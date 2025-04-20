from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>PayViya API Documentation</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            h1 { color: #333; }
        </style>
    </head>
    <body>
        <h1>PayViya API Documentation</h1>
        <p>Welcome to the PayViya API! The API documentation is available.</p>
        <p>This is a test page to confirm the Flask server is working.</p>
    </body>
    </html>
    """

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080) 