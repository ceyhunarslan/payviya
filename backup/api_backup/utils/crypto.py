import base64
import os
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

from app.core.config import settings

# Create a key from the secret key
def get_encryption_key():
    """Generate an encryption key from the app secret key"""
    salt = b'payviya_salt'  # This would ideally be stored securely
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(settings.SECRET_KEY.encode()))
    return key

def encrypt_data(data: str) -> str:
    """Encrypt sensitive data"""
    if not data:
        return None
        
    key = get_encryption_key()
    f = Fernet(key)
    encrypted_data = f.encrypt(data.encode())
    return base64.urlsafe_b64encode(encrypted_data).decode()

def decrypt_data(data: str) -> str:
    """Decrypt sensitive data"""
    if not data:
        return None
        
    key = get_encryption_key()
    f = Fernet(key)
    encrypted_data = base64.urlsafe_b64decode(data.encode())
    return f.decrypt(encrypted_data).decode() 