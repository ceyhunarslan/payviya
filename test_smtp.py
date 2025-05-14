import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Mailtrap settings
smtp_host = "smtp.mailtrap.io"
smtp_port = 2525
smtp_user = "ac4c6e994b3bdf"
smtp_pass = "afc0d3cee82453"

try:
    # Create message
    msg = MIMEMultipart()
    msg['From'] = "noreply@payviya.com"
    msg['To'] = "test@example.com"
    msg['Subject'] = "Test SMTP Connection"
    msg.attach(MIMEText("This is a test email", 'plain'))

    # Connect to server
    print(f"Connecting to {smtp_host}:{smtp_port}...")
    server = smtplib.SMTP(smtp_host, smtp_port)
    server.set_debuglevel(1)
    
    print("Starting TLS...")
    server.starttls()
    
    print("Logging in...")
    server.login(smtp_user, smtp_pass)
    
    print("Sending mail...")
    server.send_message(msg)
    
    print("Closing connection...")
    server.quit()
    
    print("Test completed successfully!")
    
except Exception as e:
    print(f"Error: {str(e)}") 