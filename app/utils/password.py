from passlib.context import CryptContext
import hashlib
import base64
import re
from typing import Tuple

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Client-side hashing parameters (must match frontend)
CLIENT_SALT = "payviya_client_salt"
CLIENT_ITERATIONS = 1000

def verify_password(client_hashed_password: str, stored_hashed_password: str) -> bool:
    """
    Verify a password against a hash.
    The client_hashed_password is the SHA-256 hash from the client,
    and stored_hashed_password is the bcrypt hash stored in the database.
    """
    # Since the client sends us the final base64 encoded hash,
    # we just need to compare it with what's stored
    return client_hashed_password == stored_hashed_password

def get_password_hash(client_hashed_password: str) -> str:
    """
    Store the client-side hashed password as is.
    The client_hashed_password is already properly hashed by the client.
    """
    return client_hashed_password

def validate_password(password: str) -> Tuple[bool, str]:
    """
    Validates that the password meets the following criteria:
    - Between 6-8 characters long
    - Contains only numeric characters
    
    Returns:
    - Tuple[bool, str]: (is_valid, error_message)
    """
    if len(password) < 6:
        return False, "Şifre en az 6 haneli olmalı"
        
    if len(password) > 8:
        return False, "Şifre en fazla 8 haneli olabilir"
    
    if not re.match(r'^\d+$', password):
        return False, "Şifre sadece rakam içermeli"
    
    return True, "" 