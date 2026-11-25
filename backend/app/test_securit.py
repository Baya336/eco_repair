from app.security import hash_password, verify_password

# Mot de passe de test
mot_de_passe = "Test123456!"

# Transformer le mot de passe en empreinte
empreinte = hash_password(mot_de_passe)

print("Empreinte créée :", empreinte)

# Vérifier le bon mot de passe
print("Bon mot de passe :", verify_password(mot_de_passe, empreinte))

# Vérifier un mauvais mot de passe
print("Mauvais mot de passe :", verify_password("Autre123!", empreinte))