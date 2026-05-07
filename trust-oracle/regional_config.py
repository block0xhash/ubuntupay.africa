"""
Ubuntu Pay — regional_config.py
THE PAN-AFRICAN TAX & FEE REPOSITORY.
"""
CORRIDOR_RULES = {
    ("KE", "NG"): {"fee": 0.003, "tax": 0.20, "tax_name": "KE Excise Duty"},
    ("KE", "ZA"): {"fee": 0.003, "tax": 0.20, "tax_name": "KE Excise Duty"},
    ("KE", "KE"): {"fee": 0.001, "tax": 0.20, "tax_name": "KE Excise Duty"},
    ("ZA", "KE"): {"fee": 0.004, "tax": 0.15, "tax_name": "ZA VAT"},
    ("ZA", "ZA"): {"fee": 0.001, "tax": 0.15, "tax_name": "ZA VAT"},
    "DEFAULT": {"fee": 0.005, "tax": 0.15, "tax_name": "Intl Service Tax"}
}

def get_country_from_phone(phone: str) -> str:
    p = "".join([c for c in phone if c.isdigit()])
    if p.startswith("27"):  return "ZA"
    if p.startswith("254"): return "KE"
    if p.startswith("234"): return "NG"
    return "Unknown"

def calculate_costs(sender_country: str, receiver_phone: str, amount: float):
    dest_country = get_country_from_phone(receiver_phone)
    rule = CORRIDOR_RULES.get((sender_country, dest_country), CORRIDOR_RULES["DEFAULT"])
    protocol_fee = amount * rule["fee"]
    tax_amount = protocol_fee * rule["tax"]
    return {
        "corridor": f"{sender_country} ➔ {dest_country}",
        "fee": round(protocol_fee, 2),
        "tax": round(tax_amount, 2),
        "tax_name": rule["tax_name"],
        "rate": f"{rule['fee']*100}%",
        "total": round(amount + protocol_fee + tax_amount, 2)
    }
