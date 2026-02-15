#!/usr/bin/env python3
"""
migrate_access_to_mariadb.py

Migrates data from the old See Our Family Access databases (.mdb files)
into the new MariaDB schema.

Sources:
  - Data/user.mdb        -> families, users, user_family_link
  - Data/<family>.mdb    -> people, couples, photos, photo_person_link,
                            comments, comment_person_link, forums,
                            forum_items, infos

Requirements:
  pip install pyodbc mysql-connector-python

  For .mdb access on Linux you also need mdbtools:
    sudo apt-get install mdbtools odbc-mdbtools

Usage:
  1. Edit the configuration section below (MariaDB credentials, .mdb paths)
  2. Run: python3 migrate_access_to_mariadb.py
  3. Check the output for any warnings or errors

The script is idempotent: it will TRUNCATE all tables before inserting.
Run createDB.sql first to create the schema.
"""

import os
import sys
import subprocess
import csv
import io
from datetime import datetime, date

try:
    import mysql.connector
except ImportError:
    print("ERROR: mysql-connector-python is required.")
    print("  pip install mysql-connector-python")
    sys.exit(1)


# =========================================================================
# CONFIGURATION - Edit these values for your environment
# =========================================================================

MARIADB_CONFIG = {
    "host": "localhost",
    "port": 3306,
    "user": "root",
    "password": "",
    "database": "seeourfamily",
}

# Path to the common user.mdb (Domain, User, LkDomainUser tables)
COMMON_MDB = "Data/user.mdb"

# Family .mdb files to migrate.
# Each entry maps a family name to its .mdb path.
# The family name must match what's in the Domain table's DomainName field.
# If you're unsure, run the script with --list-families to see what's in user.mdb.
FAMILY_MDB_FILES = {
    # "Tajan": "Data/some-tajan.mdb",
    # "Ducos": "Data/some-ducos.mdb",
    # "Moeskops": "Data/some-moeskops.mdb",
}

# =========================================================================
# MDB READING UTILITIES (uses mdbtools command-line)
# =========================================================================


def mdb_list_tables(mdb_path):
    """List all tables in an .mdb file using mdb-tables."""
    result = subprocess.run(
        ["mdb-tables", "-1", mdb_path],
        capture_output=True, text=True, check=True
    )
    return [t.strip() for t in result.stdout.strip().split("\n") if t.strip()]


def mdb_export_table(mdb_path, table_name):
    """Export a table from an .mdb file as a list of dicts using mdb-export."""
    result = subprocess.run(
        ["mdb-export", mdb_path, table_name],
        capture_output=True, text=True, check=True
    )
    if not result.stdout.strip():
        return []
    reader = csv.DictReader(io.StringIO(result.stdout))
    return list(reader)


def safe_int(val):
    """Convert a value to int, returning None if empty or invalid."""
    if val is None or val == "" or val == "null":
        return None
    try:
        return int(float(val))
    except (ValueError, TypeError):
        return None


def safe_str(val):
    """Convert a value to string, returning None if empty."""
    if val is None or val == "" or val == "null":
        return None
    return str(val).strip()


def safe_bool(val):
    """Convert Access boolean to 0/1."""
    if val is None or val == "" or val == "null":
        return None
    s = str(val).strip().lower()
    if s in ("1", "true", "-1", "yes"):
        return 1
    return 0


def parse_access_date(date_str):
    """Parse an Access date string into a Python date, or None."""
    if not date_str or date_str.strip() in ("", "null"):
        return None
    date_str = date_str.strip()
    for fmt in ("%m/%d/%Y %H:%M:%S", "%m/%d/%Y", "%Y-%m-%d %H:%M:%S",
                "%Y-%m-%d", "%d/%m/%Y", "%m/%d/%y"):
        try:
            return datetime.strptime(date_str, fmt).date()
        except ValueError:
            continue
    return None


def parse_access_datetime(dt_str):
    """Parse an Access datetime string into a Python datetime, or None."""
    if not dt_str or dt_str.strip() in ("", "null"):
        return None
    dt_str = dt_str.strip()
    for fmt in ("%m/%d/%Y %H:%M:%S", "%m/%d/%Y", "%Y-%m-%d %H:%M:%S",
                "%Y-%m-%d"):
        try:
            return datetime.strptime(dt_str, fmt)
        except ValueError:
            continue
    return None


def compute_date_and_precision(year_val, full_date_val, month_val=None, day_val=None):
    """
    Combine the old Access DtNaiss (year) + DateNaiss (full date mm/dd/yyyy)
    into a proper DATE + precision string.

    Returns (date_obj_or_None, precision_str_or_None).
    """
    full_date = parse_access_date(full_date_val) if full_date_val else None
    year = safe_int(year_val)
    month = safe_int(month_val)
    day = safe_int(day_val)

    if full_date:
        return full_date, "ymd"
    if year and month and day:
        try:
            return date(year, month, day), "ymd"
        except ValueError:
            pass
    if year and month:
        try:
            return date(year, month, 1), "ym"
        except ValueError:
            pass
    if year:
        try:
            return date(year, 1, 1), "y"
        except ValueError:
            pass
    return None, None


# =========================================================================
# MIGRATION FUNCTIONS
# =========================================================================


def migrate_common_db(cursor, mdb_path):
    """Migrate Domain, User, LkDomainUser from user.mdb."""
    print(f"\n--- Migrating common DB: {mdb_path} ---")

    if not os.path.exists(mdb_path):
        print(f"  WARNING: {mdb_path} not found, skipping common DB migration.")
        return {}

    tables = mdb_list_tables(mdb_path)
    print(f"  Tables found: {tables}")

    # --- families (from Domain table) ---
    domain_id_map = {}  # old IDDomain -> new families.id
    if "Domain" in tables:
        rows = mdb_export_table(mdb_path, "Domain")
        print(f"  Domain: {len(rows)} rows")
        for row in rows:
            if not safe_bool(row.get("DomainIsOnline", "1")):
                continue
            cursor.execute("""
                INSERT INTO families (name, title, language, date_format, package,
                                     url, hash, guest_password, admin_password, is_online)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, 1)
            """, (
                safe_str(row.get("DomainName")),
                safe_str(row.get("DomainHeadTitle")),
                safe_str(row.get("DomainLanguage")) or "ENG",
                safe_str(row.get("DomainDateFormat")) or "dmy",
                safe_str(row.get("DomainPackage")) or "Starter",
                safe_str(row.get("DomainURL")),
                safe_str(row.get("DomainRNDKey")),
                safe_str(row.get("DomainPwdGuest")),
                safe_str(row.get("DomainPwdAdmin")),
            ))
            new_id = cursor.lastrowid
            old_id = safe_int(row.get("IDDomain"))
            if old_id is not None:
                domain_id_map[old_id] = new_id
            print(f"    Family: {row.get('DomainName')} (old ID {old_id} -> new ID {new_id})")
    else:
        print("  WARNING: No 'Domain' table found in user.mdb")

    # --- users (from User table) ---
    user_id_map = {}  # old IDUser -> new users.id
    if "User" in tables:
        rows = mdb_export_table(mdb_path, "User")
        print(f"  User: {len(rows)} rows")
        for row in rows:
            cursor.execute("""
                INSERT INTO users (login, password, name, email, is_online)
                VALUES (%s, %s, %s, %s, %s)
            """, (
                safe_str(row.get("UserLogin")) or "unknown",
                safe_str(row.get("UserPassword")) or "changeme",
                safe_str(row.get("UserName")),
                safe_str(row.get("UserEmail")),
                safe_bool(row.get("UserIsOnline", "1")),
            ))
            new_id = cursor.lastrowid
            old_id = safe_int(row.get("IDUser"))
            if old_id is not None:
                user_id_map[old_id] = new_id
    else:
        print("  WARNING: No 'User' table found in user.mdb")

    # --- user_family_link (from LkDomainUser table) ---
    if "LkDomainUser" in tables:
        rows = mdb_export_table(mdb_path, "LkDomainUser")
        print(f"  LkDomainUser: {len(rows)} rows")
        for row in rows:
            old_domain_id = safe_int(row.get("IdDomain"))
            old_user_id = safe_int(row.get("IdUser"))
            new_family_id = domain_id_map.get(old_domain_id)
            new_user_id = user_id_map.get(old_user_id)
            if new_family_id and new_user_id:
                cursor.execute("""
                    INSERT IGNORE INTO user_family_link (user_id, family_id, role)
                    VALUES (%s, %s, %s)
                """, (
                    new_user_id,
                    new_family_id,
                    safe_str(row.get("Status")) or "Guest",
                ))

    return domain_id_map


def migrate_family_db(cursor, mdb_path, family_id, family_name):
    """Migrate all content tables from a family .mdb file."""
    print(f"\n--- Migrating family DB: {family_name} ({mdb_path}) -> family_id={family_id} ---")

    if not os.path.exists(mdb_path):
        print(f"  WARNING: {mdb_path} not found, skipping.")
        return

    tables = mdb_list_tables(mdb_path)
    print(f"  Tables found: {tables}")

    # --- people (from Personne) ---
    person_id_map = {}  # old IDPersonne -> new people.id
    if "Personne" in tables:
        rows = mdb_export_table(mdb_path, "Personne")
        print(f"  Personne: {len(rows)} rows")
        for row in rows:
            birth_date, birth_prec = compute_date_and_precision(
                row.get("DtNaiss"), row.get("DateNaiss"))
            death_date, death_prec = compute_date_and_precision(
                row.get("DtDec"), row.get("DateDec"))

            cursor.execute("""
                INSERT INTO people (family_id, first_name, first_names, last_name,
                                    is_male, birth_date, birth_precision, birth_place,
                                    death_date, death_precision, death_place,
                                    email, biography, links, is_online,
                                    updated_by, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 1, %s, %s)
            """, (
                family_id,
                safe_str(row.get("Prenom")),
                safe_str(row.get("Prenoms")),
                safe_str(row.get("Nom")),
                safe_bool(row.get("IsMasc")),
                birth_date,
                birth_prec,
                safe_str(row.get("LieuNaiss")),
                death_date,
                death_prec,
                safe_str(row.get("LieuDec")),
                safe_str(row.get("Email")),
                safe_str(row.get("Comm")),
                safe_str(row.get("Link")),
                safe_int(row.get("LastUpdateWho")),
                parse_access_datetime(row.get("LastUpdateWhen")),
            ))
            new_id = cursor.lastrowid
            old_id = safe_int(row.get("IDPersonne"))
            if old_id is not None:
                person_id_map[old_id] = new_id

    # --- couples (from Couple) ---
    couple_id_map = {}  # old IDCouple -> new couples.id
    if "Couple" in tables:
        rows = mdb_export_table(mdb_path, "Couple")
        print(f"  Couple: {len(rows)} rows")
        for row in rows:
            start_date, start_prec = compute_date_and_precision(
                row.get("DtCouple"), row.get("DateCouple"))

            old_masc = safe_int(row.get("IDPersMasc"))
            old_fem = safe_int(row.get("IDPersFem"))

            cursor.execute("""
                INSERT INTO couples (family_id, person1_id, person2_id,
                                     start_date, start_precision, start_place,
                                     is_online, updated_by, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, 1, %s, %s)
            """, (
                family_id,
                person_id_map.get(old_masc),
                person_id_map.get(old_fem),
                start_date,
                start_prec,
                safe_str(row.get("LieuCouple")),
                safe_int(row.get("LastUpdateWho")),
                parse_access_datetime(row.get("LastUpdateWhen")),
            ))
            new_id = cursor.lastrowid
            old_id = safe_int(row.get("IDCouple"))
            if old_id is not None:
                couple_id_map[old_id] = new_id

    # Now update people.couple_id (parent couple) using the couple_id_map
    if "Personne" in tables:
        rows = mdb_export_table(mdb_path, "Personne")
        for row in rows:
            old_person_id = safe_int(row.get("IDPersonne"))
            old_couple_id = safe_int(row.get("IDCouple"))
            couple_sort = safe_int(row.get("TriCouple"))
            new_person_id = person_id_map.get(old_person_id)
            new_couple_id = couple_id_map.get(old_couple_id)
            if new_person_id and new_couple_id:
                cursor.execute("""
                    UPDATE people SET couple_id = %s, couple_sort = %s
                    WHERE id = %s
                """, (new_couple_id, couple_sort, new_person_id))

    # --- photos (from Photo) ---
    photo_id_map = {}
    if "Photo" in tables:
        rows = mdb_export_table(mdb_path, "Photo")
        print(f"  Photo: {len(rows)} rows")
        for row in rows:
            photo_date, photo_prec = compute_date_and_precision(
                row.get("DtYear"), None,
                row.get("DtMonth"), row.get("DtDay"))

            cursor.execute("""
                INSERT INTO photos (family_id, file_name, description,
                                    photo_date, photo_precision, is_online,
                                    updated_by, updated_at)
                VALUES (%s, %s, %s, %s, %s, 1, %s, %s)
            """, (
                family_id,
                safe_str(row.get("NomPhoto")),
                safe_str(row.get("DescrPhoto")),
                photo_date,
                photo_prec,
                safe_int(row.get("LastUpdateWho")),
                parse_access_datetime(row.get("LastUpdateWhen")),
            ))
            new_id = cursor.lastrowid
            old_id = safe_int(row.get("IDPhoto"))
            if old_id is not None:
                photo_id_map[old_id] = new_id

    # --- photo_person_link (from LienPhotoPerso) ---
    if "LienPhotoPerso" in tables:
        rows = mdb_export_table(mdb_path, "LienPhotoPerso")
        print(f"  LienPhotoPerso: {len(rows)} rows")
        for row in rows:
            new_photo_id = photo_id_map.get(safe_int(row.get("IdPhoto")))
            new_person_id = person_id_map.get(safe_int(row.get("IdPersonne")))
            if new_photo_id and new_person_id:
                cursor.execute("""
                    INSERT IGNORE INTO photo_person_link (photo_id, person_id, sort_order)
                    VALUES (%s, %s, %s)
                """, (
                    new_photo_id,
                    new_person_id,
                    safe_int(row.get("SortKey")) or 0,
                ))

    # --- comments (from Commentaire) ---
    comment_id_map = {}
    if "Commentaire" in tables:
        rows = mdb_export_table(mdb_path, "Commentaire")
        print(f"  Commentaire: {len(rows)} rows")
        for row in rows:
            cursor.execute("""
                INSERT INTO comments (family_id, title, event_date, body,
                                      is_online, updated_by, updated_at)
                VALUES (%s, %s, %s, %s, 1, %s, %s)
            """, (
                family_id,
                safe_str(row.get("Titre")),
                safe_str(row.get("DtVecu")),
                safe_str(row.get("Comm")),
                safe_int(row.get("LastUpdateWho")),
                parse_access_datetime(row.get("LastUpdateWhen")),
            ))
            new_id = cursor.lastrowid
            old_id = safe_int(row.get("IDCommentaire"))
            if old_id is not None:
                comment_id_map[old_id] = new_id

    # --- comment_person_link (from LienCommPerso) ---
    if "LienCommPerso" in tables:
        rows = mdb_export_table(mdb_path, "LienCommPerso")
        print(f"  LienCommPerso: {len(rows)} rows")
        for row in rows:
            new_comment_id = comment_id_map.get(safe_int(row.get("IdCommentaire")))
            new_person_id = person_id_map.get(safe_int(row.get("IdPersonne")))
            if new_comment_id and new_person_id:
                cursor.execute("""
                    INSERT IGNORE INTO comment_person_link (comment_id, person_id, sort_order)
                    VALUES (%s, %s, %s)
                """, (
                    new_comment_id,
                    new_person_id,
                    safe_int(row.get("SortKey")) or 0,
                ))

    # --- forums (from Forum) ---
    forum_id_map = {}
    if "Forum" in tables:
        rows = mdb_export_table(mdb_path, "Forum")
        print(f"  Forum: {len(rows)} rows")
        for row in rows:
            cursor.execute("""
                INSERT INTO forums (family_id, parent_id, sort_order, admin_name,
                                    title, is_online, updated_by, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                family_id,
                safe_int(row.get("IdDad")) if safe_int(row.get("IdDad")) else None,
                safe_int(row.get("ForumSort")) or 0,
                safe_str(row.get("ForumAdmin")),
                safe_str(row.get("ForumTitle")),
                safe_bool(row.get("ForumIsOnline", "1")),
                safe_int(row.get("LastUpdateWho")),
                parse_access_datetime(row.get("LastUpdateWhen")),
            ))
            new_id = cursor.lastrowid
            old_id = safe_int(row.get("IDForum"))
            if old_id is not None:
                forum_id_map[old_id] = new_id

    # --- forum_items (from ForumItem) ---
    if "ForumItem" in tables:
        rows = mdb_export_table(mdb_path, "ForumItem")
        print(f"  ForumItem: {len(rows)} rows")
        for row in rows:
            new_forum_id = forum_id_map.get(safe_int(row.get("IdForum")))
            if new_forum_id:
                posted = parse_access_datetime(row.get("ForumItemDate"))
                cursor.execute("""
                    INSERT INTO forum_items (forum_id, title, author_name,
                                             author_email, body, posted_at, is_online)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, (
                    new_forum_id,
                    safe_str(row.get("ForumItemTitle")),
                    safe_str(row.get("ForumItemFrom")),
                    safe_str(row.get("ForumItemEmail")),
                    safe_str(row.get("ForumItemBody")),
                    posted or datetime.now(),
                    safe_bool(row.get("ForumItemIsOnline", "1")),
                ))

    # --- infos (from Info) ---
    if "Info" in tables:
        rows = mdb_export_table(mdb_path, "Info")
        print(f"  Info: {len(rows)} rows")
        for row in rows:
            cursor.execute("""
                INSERT INTO infos (family_id, location, content, is_online,
                                   updated_by, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                family_id,
                safe_str(row.get("InfoLocation")),
                safe_str(row.get("InfoContent")),
                safe_bool(row.get("InfoIsOnline", "1")),
                safe_int(row.get("LastUpdateWho")),
                parse_access_datetime(row.get("LastUpdateWhen")),
            ))

    print(f"  Done. Migrated: {len(person_id_map)} people, {len(couple_id_map)} couples, "
          f"{len(photo_id_map)} photos, {len(comment_id_map)} comments, "
          f"{len(forum_id_map)} forums")


# =========================================================================
# MAIN
# =========================================================================

def main():
    # --- List families mode ---
    if len(sys.argv) > 1 and sys.argv[1] == "--list-families":
        print(f"Listing families from {COMMON_MDB}...")
        if not os.path.exists(COMMON_MDB):
            print(f"  ERROR: {COMMON_MDB} not found")
            sys.exit(1)
        rows = mdb_export_table(COMMON_MDB, "Domain")
        for row in rows:
            db_file = row.get("DomainDB", "?")
            print(f"  IDDomain={row.get('IDDomain')}  "
                  f"Name={row.get('DomainName')}  "
                  f"DB={db_file}  "
                  f"Online={row.get('DomainIsOnline')}")
        sys.exit(0)

    # --- Check prerequisites ---
    try:
        subprocess.run(["mdb-tables", "--version"], capture_output=True, check=True)
    except FileNotFoundError:
        print("ERROR: mdbtools is required but not found.")
        print("  Ubuntu/Debian: sudo apt-get install mdbtools")
        print("  macOS:         brew install mdbtools")
        sys.exit(1)

    # --- Connect to MariaDB ---
    print("Connecting to MariaDB...")
    conn = mysql.connector.connect(**MARIADB_CONFIG)
    cursor = conn.cursor()

    # Disable FK checks during migration
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

    # Truncate all tables (idempotent migration)
    print("Truncating existing data...")
    for table in ["forum_items", "forums", "infos",
                   "comment_person_link", "comments",
                   "photo_person_link", "photos",
                   "couples", "people",
                   "user_family_link", "users", "families"]:
        cursor.execute(f"TRUNCATE TABLE `{table}`")

    # --- Step 1: Migrate common DB ---
    domain_id_map = migrate_common_db(cursor, COMMON_MDB)

    # --- Step 2: Build family name -> new family_id lookup ---
    cursor.execute("SELECT id, name FROM families")
    family_name_to_id = {name: fid for fid, name in cursor.fetchall()}

    # --- Step 3: Migrate each family DB ---
    if not FAMILY_MDB_FILES:
        print("\n*** WARNING: No family .mdb files configured in FAMILY_MDB_FILES. ***")
        print("*** Edit this script to add your family .mdb file paths.          ***")
        print("*** Use --list-families to see what's in user.mdb.                ***")
    else:
        for family_name, mdb_path in FAMILY_MDB_FILES.items():
            family_id = family_name_to_id.get(family_name)
            if family_id is None:
                print(f"\n  WARNING: Family '{family_name}' not found in families table. "
                      f"Was it in user.mdb? Skipping.")
                continue
            migrate_family_db(cursor, mdb_path, family_id, family_name)

    # Re-enable FK checks
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")

    # Commit
    conn.commit()
    print("\n=== Migration complete! ===")

    # Summary
    for table in ["families", "users", "user_family_link", "people", "couples",
                   "photos", "photo_person_link", "comments", "comment_person_link",
                   "forums", "forum_items", "infos"]:
        cursor.execute(f"SELECT COUNT(*) FROM `{table}`")
        count = cursor.fetchone()[0]
        print(f"  {table}: {count} rows")

    cursor.close()
    conn.close()


if __name__ == "__main__":
    main()
