from flask import Flask, render_template, request
import boto3
import json
import os
from dotenv import load_dotenv
from pathlib import Path

load_dotenv()
# initialize flask app 
app = Flask(__name__)

# AWS S3 configuration
s3_client = boto3.client(
    's3',
    aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
    aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
    region_name=os.getenv('AWS_REGION')
)
# bucket_name = os.getenv('AWS_BUCKET_NAME')
bucket_name_path = Path("bucket_name.txt")
with open(bucket_name_path, "r") as f:
    bucket_name = f.read().strip()

print(f"Using bucket: {bucket_name}")

@app.route('/')
def index():
    """Home page listing available weather data files"""
    try:
        # List all weather files in the bucket
         
        response = s3_client.list_objects_v2(Bucket=bucket_name, Prefix="weather-data/")
      
        files = [obj['Key'] for obj in response.get('Contents', [])]
        return render_template('index.html', files=files)
    except Exception as e:
        return f"Error listing files: {e}"

@app.route('/weather/<path:file_key>')
def view_weather(file_key):
    """View specific weather data"""
    try:
        # Get the weather file from S3
        response = s3_client.get_object(Bucket=bucket_name, Key=file_key)
        weather_data = json.loads(response['Body'].read())
        return render_template('weather.html', weather=weather_data)
    except Exception as e:
        return f"Error fetching file: {e}"

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)
