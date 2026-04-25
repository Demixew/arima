import sqlite3
import sys

conn = sqlite3.connect('wata_smart_tracker.db')
cursor = conn.cursor()

cursor.execute("PRAGMA table_info(task_reminders)")
cols = {c[1] for c in cursor.fetchall()}

print("Current columns:", cols)

missing = []
if 'escalated_to_parent' not in cols:
    missing.append('escalated_to_parent')
    cursor.execute("ALTER TABLE task_reminders ADD COLUMN escalated_to_parent INTEGER DEFAULT 0")
    print("Added escalated_to_parent")

if 'parent_alert_message' not in cols:
    missing.append('parent_alert_message')
    cursor.execute("ALTER TABLE task_reminders ADD COLUMN parent_alert_message TEXT")
    print("Added parent_alert_message")

conn.commit()

cursor.execute("PRAGMA table_info(task_reminders)")
cols_after = {c[1] for c in cursor.fetchall()}
print("Columns after:", cols_after)

conn.close()
print("Done!")