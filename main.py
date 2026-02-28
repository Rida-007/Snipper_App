from fastapi import FastAPI
from pydantic import BaseModel
import mysql.connector
import random

app = FastAPI()

# -----------------------------
# DATABASE CONNECTION
# -----------------------------
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="*123#yolo",   # 🔴 change if needed
    database="deep_action_sniper"
)

cursor = db.cursor()

# -----------------------------
# DATA MODEL
# -----------------------------
class Snipe(BaseModel):
    url: str
    target_price: float

# -----------------------------
# ADD NEW SNIPE
# -----------------------------
@app.post("/add_snipe")
def add_snipe(snipe: Snipe):

    query = """
    INSERT INTO snipes (url, target_price, current_price, status)
    VALUES (%s, %s, %s, %s)
    """

    values = (
        snipe.url,
        snipe.target_price,
        100,  # Starting price (initial)
        "Active"
    )

    cursor.execute(query, values)
    db.commit()

    return {
        "message": "Snipe added successfully",
        "id": cursor.lastrowid
    }

# -----------------------------
# GET ALL SNIPES
# -----------------------------
@app.get("/get_snipes")
def get_snipes():
    cursor.execute("""
        SELECT id, url, target_price, current_price, status, created_at
        FROM snipes
        ORDER BY id DESC
    """)
    result = cursor.fetchall()

    snipes_list = []

    for row in result:
        target_price = float(row[2] or 0)
        current_price = float(row[3] or 0)

        profit = current_price - target_price

        snipes_list.append({
            "id": row[0],
            "url": row[1],
            "target_price": target_price,
            "current_price": current_price,
            "profit": profit,
            "status": row[4] or "Unknown",
            "created_at": str(row[5]) if row[5] else ""
        })

    return {"snipes": snipes_list}

# -----------------------------
# SIMULATE MARKET (Updated)
# -----------------------------
@app.post("/simulate_market")
def simulate_market():

    cursor.execute("SELECT id, target_price, current_price FROM snipes")
    snipes = cursor.fetchall()

    if not snipes:
        return {"message": "No snipes available"}

    for s in snipes:
        snipe_id = s[0]
        target_price = float(s[1] or 0)
        current_price = float(s[2] or 0)

        # If current price is zero (first simulation), we start near the target
        if current_price == 0:
            current_price = target_price + random.randint(-30, 30)

        # Gradual market movement (simulating price changes)
        movement = random.randint(-10, 10)
        new_price = current_price + movement

        # Ensure price doesn't go below 1
        if new_price < 1:
            new_price = 1

        # Check if the target price has been hit
        if new_price <= target_price:
            status = "Target Hit"
        else:
            status = "Watching"

        # Update the snipes table with the new price and status
        update_query = """
        UPDATE snipes
        SET current_price = %s,
            status = %s
        WHERE id = %s
        """

        cursor.execute(update_query, (new_price, status, snipe_id))

    db.commit()

    return {"message": "Market simulated successfully"}