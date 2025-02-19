FROM --platform=linux/amd64 python:3.11-alpine

# set a working directory 
WORKDIR /weather-dashboard

# copy the requirement.txt to the working directory
COPY requirements.txt .

# install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# copy the rest of the application source code into the working directory of container
COPY . .

# make the script executable 
RUN chmod +x start.sh

EXPOSE 5000

# run the application , src/weather_dashboard then app.py
CMD ["./start.sh"]