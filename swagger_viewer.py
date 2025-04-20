from flask import Flask, render_template_string, request
import yaml
import json
import os
import re
import glob

app = Flask(__name__)

def find_api_specs():
    """Find all OpenAPI spec files in the project"""
    specs = []
    
    # Try various common paths for OpenAPI specs
    spec_paths = [
        'recommendations_api_spec.yaml',
        'venv/recommendations_api_spec.yaml',
        'api_spec.yaml',
        'openapi.yaml',
        'swagger.yaml',
        'openapi.json',
        'swagger.json'
    ]
    
    for path in spec_paths:
        if os.path.exists(path):
            try:
                with open(path, 'r') as file:
                    if path.endswith('.yaml') or path.endswith('.yml'):
                        spec = yaml.safe_load(file)
                    else:
                        spec = json.load(file)
                specs.append({
                    'name': os.path.basename(path),
                    'spec': spec
                })
            except Exception as e:
                print(f"Error loading {path}: {e}")
    
    return specs

def find_api_endpoints():
    """Scan the codebase for API endpoints"""
    endpoints = []
    
    # Directories to search
    dirs_to_search = [
        'venv/app',
        'app',
        'venv/mobile_app',
        'mobile_app'
    ]
    
    # Look for FastAPI route definitions
    route_patterns = [
        r'@(?:app|router|api_router)\.(?:get|post|put|delete|patch)\s*\(\s*[\'"]([^\'"]+)[\'"]',
        r'\.include_router\([^,]+,\s*prefix=[\'"]([^\'"]+)[\'"]'
    ]
    
    for directory in dirs_to_search:
        if not os.path.exists(directory):
            continue
            
        # Find Python files
        for py_file in glob.glob(f"{directory}/**/*.py", recursive=True):
            try:
                with open(py_file, 'r') as file:
                    content = file.read()
                    
                for pattern in route_patterns:
                    for match in re.finditer(pattern, content):
                        path = match.group(1)
                        if path.startswith('/'):
                            endpoints.append({
                                'path': path,
                                'file': os.path.relpath(py_file),
                            })
                        elif 'prefix=' in pattern:  # This is a router inclusion
                            # Look for actual routes in this file
                            router_routes = re.findall(r'@router\.(?:get|post|put|delete|patch)\s*\(\s*[\'"]([^\'"]+)[\'"]', content)
                            for route in router_routes:
                                full_path = path + route
                                endpoints.append({
                                    'path': full_path,
                                    'file': os.path.relpath(py_file),
                                })
            except Exception as e:
                print(f"Error processing {py_file}: {e}")
    
    return endpoints

@app.route('/')
def index():
    """List all available API specs and discovered endpoints"""
    specs = find_api_specs()
    endpoints = find_api_endpoints()
    
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>PayViya API Documentation</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 20px; }
            h1, h2 { color: #333; }
            .section { margin-bottom: 30px; }
            ul { list-style-type: none; padding: 0; }
            li { margin: 10px 0; }
            a { color: #0066cc; text-decoration: none; padding: 10px; background: #f0f0f0; 
                border-radius: 4px; display: inline-block; }
            a:hover { background: #e0e0e0; }
            .endpoint { font-family: monospace; padding: 10px; background: #f8f8f8; border-left: 4px solid #0066cc; margin: 5px 0; }
            .file-path { color: #666; font-size: 0.8em; margin-left: 10px; }
        </style>
    </head>
    <body>
        <h1>PayViya API Documentation</h1>
        
        <div class="section">
            <h2>OpenAPI Specifications</h2>
            {% if specs %}
            <ul>
                {% for spec in specs %}
                <li><a href="/swagger-ui?spec={{ spec.name }}">{{ spec.name }}</a></li>
                {% endfor %}
            </ul>
            {% else %}
            <p>No API specifications found.</p>
            {% endif %}
        </div>
        
        <div class="section">
            <h2>Discovered API Endpoints</h2>
            {% if endpoints %}
            <div>
                {% for endpoint in endpoints %}
                <div class="endpoint">
                    {{ endpoint.path }} <span class="file-path">({{ endpoint.file }})</span>
                </div>
                {% endfor %}
            </div>
            {% else %}
            <p>No additional API endpoints discovered in the codebase.</p>
            {% endif %}
        </div>
    </body>
    </html>
    """
    
    return render_template_string(html, specs=specs, endpoints=endpoints)

@app.route('/swagger-ui')
def swagger_ui():
    """Display Swagger UI for the selected spec"""
    spec_name = request.args.get('spec', 'recommendations_api_spec.yaml')
    
    specs = find_api_specs()
    selected_spec = None
    
    for spec in specs:
        if spec['name'] == spec_name:
            selected_spec = spec['spec']
            break
    
    if not selected_spec:
        return "API specification not found", 404
    
    # Convert to JSON for the Swagger UI
    api_spec_json = json.dumps(selected_spec)
    
    # HTML template with Swagger UI
    html = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>Swagger UI - {{ spec_name }}</title>
        <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@3/swagger-ui.css">
        <style>
            .topbar { display: none; }
            body { margin: 0; }
            .back-link { padding: 10px; background: #f8f8f8; border-bottom: 1px solid #ddd; }
            .back-link a { color: #0066cc; text-decoration: none; }
        </style>
    </head>
    <body>
        <div class="back-link">
            <a href="/">← Back to API list</a>
            <span style="margin-left: 20px; font-weight: bold;">{{ spec_name }}</span>
        </div>
        <div id="swagger-ui"></div>
        <script src="https://unpkg.com/swagger-ui-dist@3/swagger-ui-bundle.js"></script>
        <script>
            const ui = SwaggerUIBundle({
                spec: {{ api_spec_json|safe }},
                dom_id: '#swagger-ui',
                presets: [
                    SwaggerUIBundle.presets.apis,
                    SwaggerUIBundle.SwaggerUIStandalonePreset
                ],
                layout: "BaseLayout",
                deepLinking: true
            });
        </script>
    </body>
    </html>
    """
    
    return render_template_string(html, api_spec_json=api_spec_json, spec_name=spec_name)

if __name__ == '__main__':
    app.run(debug=True, port=8080) 