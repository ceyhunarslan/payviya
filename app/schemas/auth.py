from pydantic import BaseModel

class FCMTokenUpdate(BaseModel):
    fcm_token: str
    device_id: str
    device_type: str  # ios, android, web 

class LoginRequest(BaseModel):
    username: str
    password: str
    fcm_token: str | None = None
    device_id: str | None = None
    device_type: str | None = None 