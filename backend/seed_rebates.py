# backend/seed_rebates_australia_full.py

import os
from firebase_admin import credentials, firestore, initialize_app
from dotenv import load_dotenv

load_dotenv()
key_path = os.getenv("FIREBASE_KEY_PATH")
if not key_path:
    raise ValueError("FIREBASE_KEY_PATH not set")

cred = credentials.Certificate(key_path)
try:
    initialize_app(cred)
except ValueError:
    pass
db = firestore.client()

# Your comprehensive rebate list, now fully structured for the API
rebates = [
    # Federal
    {
        "id": "federal_sres",
        "name": "Small-scale Renewable Energy Scheme (SRES)",
        "description": "STC subsidy for solar/wind/hydro/hot water, provided as a point-of-sale discount.",
        "amount": 4000,
        "location": "AUS",
        "income_max": 300000
    },
    {
        "id": "federal_energy_bill_relief_2025",
        "name": "Energy Bill Relief Fund Extension 2025",
        "description": "Up to A$300 rebate applied directly to electricity bills for eligible households.",
        "amount": 300,
        "location": "AUS",
        "income_max": 300000
    },
    # ACT
    {
        "id": "act_access_to_electric",
        "name": "Access to Electric Program",
        "description": "Fully funded electrification/upgrades for hardship cases and low-income households.",
        "amount": 5000,
        "location": "ACT",
        "income_max": 75000
    },
    {
        "id": "act_fridge_buyback",
        "name": "Fridge Buyback Program",
        "description": "Free removal of an old, inefficient fridge plus a $30 electricity rebate.",
        "amount": 30,
        "location": "ACT",
        "income_max": 300000
    },
    # NSW
    {
        "id": "nsw_low_income_rebate",
        "name": "NSW Low Income Energy Rebate",
        "description": "An annual rebate of approximately $285 for low income households.",
        "amount": 285,
        "location": "NSW",
        "income_max": 75000
    },
    {
        "id": "nsw_gas_rebate",
        "name": "NSW Gas Rebate",
        "description": "An annual rebate of $110 to help eligible households with their gas bills.",
        "amount": 110,
        "location": "NSW",
        "income_max": 300000
    },
    # VIC
    {
        "id": "vic_veu",
        "name": "Victorian Energy Upgrades (VEU)",
        "description": "Provides discounts on energy-efficient products like lighting, heating, and hot water systems.",
        "amount": 800,
        "location": "VIC",
        "income_max": 300000
    },
    {
        "id": "vic_solar_homes",
        "name": "Solar Homes Program",
        "description": "$1,400 rebate for solar panels, with options for hot water and batteries.",
        "amount": 1400,
        "location": "VIC",
        "income_max": 210000
    },
    {
        "id": "vic_power_saving_bonus",
        "name": "Power Saving Bonus",
        "description": "A $250 one-off rebate for households who use the Victorian Energy Compare website.",
        "amount": 250,
        "location": "VIC",
        "income_max": 300000
    },
    # QLD
    {
        "id": "qld_cost_of_living_rebate",
        "name": "QLD Cost of Living Electricity Rebate",
        "description": "A significant rebate of up to $1,000 per year applied directly to household electricity bills.",
        "amount": 1000,
        "location": "QLD",
        "income_max": 300000
    },
    {
        "id": "qld_appliance_rebate",
        "name": "QLD Appliance Energy Efficiency Rebate",
        "description": "Rebates from $300 to $1,000 for purchasing new, energy-efficient appliances.",
        "amount": 1000,
        "location": "QLD",
        "income_max": 180000
    },
    # SA
    {
        "id": "sa_reps",
        "name": "SA Retailer Energy Productivity Scheme (REPS)",
        "description": "Incentives for households to install energy-saving measures, offered via energy retailers.",
        "amount": 500,
        "location": "SA",
        "income_max": 250000
    },
    # WA
    {
        "id": "wa_eces",
        "name": "WA Energy Concession Extension Scheme",
        "description": "Provides an annual electricity concession of approximately $326 for eligible households.",
        "amount": 326,
        "location": "WA",
        "income_max": 75000
    },
    # TAS
    {
        "id": "tas_heating_allowance",
        "name": "Tasmania Heating Allowance",
        "description": "An annual payment of $56 to assist pensioners with the cost of heating their homes.",
        "amount": 56,
        "location": "TAS",
        "income_max": 75000
    },
    # NT
    {
        "id": "nt_energy_rebate",
        "name": "Northern Territory Electricity Rebate",
        "description": "A direct rebate of $350 applied annually to household electricity bills.",
        "amount": 350,
        "location": "NT",
        "income_max": 300000
    }
]

print("Seeding full Australian rebates dataset...")
# Clear the existing collection for a fresh start
try:
    for doc in db.collection("rebates").stream():
        doc.reference.delete()
    print("Cleared existing rebates collection.")
except Exception as e:
    print(f"Could not clear collection (it may not exist yet): {e}")

# Seed the new data
for rebate in rebates:
    try:
        db.collection("rebates").document(rebate["id"]).set(rebate)
        print(f"  Seeded: {rebate['id']}")
    except Exception as e:
        print(f"  ⇢ Failed to seed {rebate['id']}: {e}")

print("Seeding complete.")