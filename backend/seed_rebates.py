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

rebates = [
    # Federal
    {
        "id": "federal_sres",
        "name": "Small-scale Renewable Energy Scheme (SRES)",
        "level": "federal",
        "benefit": "STC subsidy for solar/wind/hydro/hot water",
        "region": "All states/territories",
    },
    {
        "id": "federal_energy_bill_relief_2025",
        "name": "Energy Bill Relief Fund Extension 2025",
        "level": "federal",
        "benefit": "Up to A$150 rebate (2×A$75 installments)",
        "region": "All states/territories",
    },
    # ACT
    {
        "id": "act_access_to_electric",
        "name": "Access to Electric Program",
        "level": "territory",
        "benefit": "Fully funded electrification/upgrades for hardship cases",
        "region": "ACT",
    },
    {
        "id": "act_fridge_buyback",
        "name": "Fridge Buyback Program",
        "level": "territory",
        "benefit": "Free removal + A$30 electricity rebate",
        "region": "ACT",
    },
    {
        "id": "act_life_support",
        "name": "ACT Life Support Rebate",
        "level": "territory",
        "benefit": "Support rebate for life-support equipment users",
        "region": "ACT",
    },
    {
        "id": "act_cds",
        "name": "ACT Container Deposit Scheme",
        "level": "territory",
        "benefit": "A$0.10 per eligible container",
        "region": "ACT",
    },
    # NSW
    {
        "id": "nsw_low_income_rebate",
        "name": "NSW Low Income Energy Rebate",
        "level": "state",
        "benefit": "~A$285/year for low income households",
        "region": "NSW",
    },
    {
        "id": "nsw_gas_rebate",
        "name": "NSW Gas Rebate",
        "level": "state",
        "benefit": "A$110/year",
        "region": "NSW",
    },
    {
        "id": "nsw_medical_energy_rebate",
        "name": "NSW Medical Energy Rebate",
        "level": "state",
        "benefit": "Up to A$285/year for eligible medical needs",
        "region": "NSW",
    },
    # VIC
    {
        "id": "vic_veu",
        "name": "Victorian Energy Upgrades (VEU)",
        "level": "state",
        "benefit": "Rebates on energy-efficient products (lighting, heating, etc.)",
        "region": "VIC",
    },
    {
        "id": "vic_solar_homes",
        "name": "Solar Homes Program",
        "level": "state",
        "benefit": "A$1,400 solar / A$1,000 hot water / A$3,500 battery rebates + loans",
        "region": "VIC",
    },
    {
        "id": "vic_power_saving_bonus",
        "name": "Power Saving Bonus",
        "level": "state",
        "benefit": "A$250 one-off rebate via Energy Compare",
        "region": "VIC",
    },
    {
        "id": "vic_cds",
        "name": "Victoria Container Deposit Scheme",
        "level": "state",
        "benefit": "A$0.10 per container",
        "region": "VIC",
    },
    # QLD
    {
        "id": "qld_electricity_rebate",
        "name": "Queensland Electricity Rebate",
        "level": "state",
        "benefit": "A$372/year",
        "region": "QLD",
    },
    {
        "id": "qld_cost_of_living_rebate",
        "name": "QLD Cost of Living Electricity Rebate",
        "level": "state",
        "benefit": "Up to A$1,000/year",
        "region": "QLD",
    },
    {
        "id": "qld_appliance_rebate",
        "name": "QLD Appliance Energy Efficiency Rebate",
        "level": "state",
        "benefit": "A$300–A$1,000 for efficient appliances",
        "region": "QLD",
    },
    {
        "id": "qld_peak_smart_ac",
        "name": "QLD PeakSmart AC Incentive",
        "level": "state",
        "benefit": "Up to A$400",
        "region": "QLD",
    },
    {
        "id": "qld_cds",
        "name": "QLD Containers for Change (CDS)",
        "level": "state",
        "benefit": "A$0.10 per container; includes wine/spirit bottles",
        "region": "QLD",
    },
    # SA
    {
        "id": "sa_reps",
        "name": "SA Retailer Energy Productivity Scheme (REPS)",
        "level": "state",
        "benefit": "Lower energy costs for households & businesses",
        "region": "SA",
    },
    {
        "id": "sa_cds",
        "name": "SA Container Deposit Scheme",
        "level": "state",
        "benefit": "A$0.10 per container; expanding container types",
        "region": "SA",
    },
    # WA
    {
        "id": "wa_eces",
        "name": "WA Energy Concession Extension Scheme",
        "level": "state",
        "benefit": "~A$326/year + child & AC rebates",
        "region": "WA",
    },
    {
        "id": "wa_cds",
        "name": "WA Containers for Change (CDS)",
        "level": "state",
        "benefit": "A$0.10 per container",
        "region": "WA",
    },
    # TAS
    {
        "id": "tas_concession",
        "name": "Tasmania Electricity Concession",
        "level": "state",
        "benefit": "Daily discount (~172 cents/day)",
        "region": "TAS",
    },
    {
        "id": "tas_heating_allowance",
        "name": "Tasmania Heating Allowance",
        "level": "state",
        "benefit": "A$56/year for pensioners",
        "region": "TAS",
    },
    {
        "id": "tas_ebrf",
        "name": "Tasmania EBRF Top-Up",
        "level": "state",
        "benefit": "A$250/year (2 years)",
        "region": "TAS",
    },
    {
        "id": "tas_cds",
        "name": "Tasmania Recycle Rewards (CDS)",
        "level": "state",
        "benefit": "A$0.10 per container",
        "region": "TAS",
    },
    # NT
    {
        "id": "nt_energy_rebate",
        "name": "Northern Territory Electricity Rebate",
        "level": "territory",
        "benefit": "A$350/year",
        "region": "NT",
    },
    {
        "id": "nt_cds",
        "name": "Northern Territory Container Deposit Scheme",
        "level": "territory",
        "benefit": "A$0.10 per container",
        "region": "NT",
    },
]

print("Seeding full Australian rebates dataset…")
for r in rebates:
    try:
        db.collection("rebates").document(r["id"]).set(r)
        print(f" Seeded: {r['id']}")
    except Exception as e:
        print(f" ⇢ Failed to seed {r['id']}: {e}")
print("Seeding complete.")
