from typing import Any, Dict, Optional
import logging
from fastapi import HTTPException
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.core.config import settings
import traceback
import asyncio
from functools import partial
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
from pathlib import Path

logger = logging.getLogger(__name__)

conf = ConnectionConfig(
    MAIL_USERNAME=settings.SMTP_USERNAME,
    MAIL_PASSWORD=settings.SMTP_PASSWORD,
    MAIL_FROM=settings.SMTP_FROM_EMAIL,
    MAIL_PORT=settings.SMTP_PORT,
    MAIL_SERVER=settings.SMTP_HOST,
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    USE_CREDENTIALS=True
)

async def send_reset_password_email(
    email_to: str,
    verification_code: str,
    user_name: str
) -> None:
    """
    Send verification code email for password reset
    """
    html = f"""
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2 style="color: #333;">PayViya Şifre Yenileme</h2>
            <p>Merhaba {user_name},</p>
            <p>Şifre yenileme talebiniz için doğrulama kodunuz:</p>
            <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; text-align: center; font-size: 24px; letter-spacing: 5px; margin: 20px 0;">
                <strong>{verification_code}</strong>
            </div>
            <p>Bu kod 15 dakika süreyle geçerlidir.</p>
            <p>Eğer bu talebi siz yapmadıysanız, lütfen bu e-postayı dikkate almayın.</p>
            <p>Saygılarımızla,<br>PayViya Ekibi</p>
        </div>
    """

    message = MessageSchema(
        subject="PayViya - Şifre Yenileme Doğrulama Kodu",
        recipients=[email_to],
        body=html,
        subtype="html"
    )

    fm = FastMail(conf)
    await fm.send_message(message)

def send_password_reset_email(email: str, token: str):
    reset_link = f"https://payviya.com/reset-password?token={token}"
    html_content = f"""
        <html>
            <body>
                <h2>Merhaba,</h2>
                <p>PayViya hesabınız için şifre sıfırlama talebinde bulundunuz.</p>
                <p>Şifrenizi sıfırlamak için aşağıdaki bağlantıya tıklayın:</p>
                <p><a href="{reset_link}">Şifremi Sıfırla</a></p>
                <p>Bu talebi siz yapmadıysanız, bu e-postayı görmezden gelebilirsiniz.</p>
                <br>
                <p>Saygılarımızla,</p>
                <p>PayViya Ekibi</p>
            </body>
        </html>
        """ 