from typing import Any
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

logger = logging.getLogger(__name__)

async def send_reset_password_email(
    email_to: str,
    reset_link: str,
    user_name: str,
) -> None:
    """
    Send password reset email to user using Mailtrap for development.
    """
    try:
        # Create the email message
        message = MIMEMultipart()
        message["From"] = settings.SMTP_FROM_EMAIL
        message["To"] = email_to
        message["Subject"] = "PayViya - Şifre Sıfırlama"

        # Create HTML content
        html = f"""
        <html>
            <body>
                <h2>Merhaba {user_name},</h2>
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
        
        # Attach HTML content
        message.attach(MIMEText(html, "html"))

        # Log connection attempt
        logger.info(f"Connecting to SMTP server: {settings.SMTP_HOST}:{settings.SMTP_PORT}")
        
        def send_email():
            # Create server connection
            server = smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT)
            server.set_debuglevel(1)
            
            # Start TLS
            logger.info("Starting TLS...")
            server.starttls()
            
            # Login
            logger.info("Logging in...")
            server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            
            # Send email
            logger.info("Sending email...")
            server.send_message(message)
            
            # Close connection
            logger.info("Closing connection...")
            server.quit()
            
            return True

        # Run the email sending in a thread pool
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, send_email)
        
        logger.info(f"Password reset email sent successfully to {email_to}")
        
    except Exception as e:
        logger.error(f"Error sending password reset email: {str(e)}")
        logger.error(f"Full error details: {traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to send password reset email: {str(e)}"
        )

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