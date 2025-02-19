# **Python Weather Dashboard** 🌦️

## **📌 Overview**

The **Python Weather Dashboard** is a cloud-native application that fetches real-time weather data for multiple cities and displays it via a web-based interface. The application is deployed on **AWS ECS Fargate** using **Terraform** for Infrastructure as Code (IaC). The backend fetches weather data from OpenWeather API and stores the results in an **Amazon S3 bucket**, while the frontend (Flask app) provides a user-friendly interface to view weather reports.

---

## **📁 Project Structure**

```
weather-dashboard/
│── src/
│   ├── app.py                     # Flask frontend application
│   ├── weather_dashboard.py        # Script fetching weather data and storing it in S3
│   ├── templates/
│   │   ├── index.html              # Main HTML file for the dashboard
│   │   ├── weather.html             # Weather details page
│── terraform/
│   ├── main.tf                     # Terraform configuration for AWS infrastructure
│   ├── variables.tf                 # Terraform variables
│   ├── outputs.tf                   # Terraform outputs
│── Dockerfile                      # Docker configuration for the application
│── .env                            # Environment variables
│── README.md                       # Project documentation
│── requirements.txt                 # Python dependencies
│── start.sh                         # Startup script for running the app
```

---

## **🛠 Technologies Used**

- **Python** (Flask, Boto3)
- **Terraform** (AWS Infrastructure as Code)
- **AWS ECS Fargate** (Serverless container orchestration)
- **AWS ECR** (Container Registry for Docker images)
- **AWS ALB** (Application Load Balancer)
- **AWS S3** (Data storage for weather reports)
- **AWS CloudWatch** (Logging and monitoring)
- **Docker** (Containerization)

---

## **🚀 Deployment Architecture**

### **Cloud Components**

1. **AWS ECS Fargate** → Runs the containerized Flask app.
2. **AWS ECR** → Stores the Docker image.
3. **AWS ALB** → Directs traffic to ECS tasks.
4. **AWS S3** → Stores weather reports in JSON format.
5. **AWS CloudWatch** → Logs and monitors ECS tasks.
6. **Terraform** → Automates infrastructure provisioning.

![AWS Architecture](https://user-images.githubusercontent.com/123456789/diagram-placeholder.png)

---

## **📌 Prerequisites**

Ensure you have the following installed:

- **Docker** 🐳
- **AWS CLI** (Configured with valid credentials)
- **Terraform** (v1.3+)
- **Python 3.11+** (If testing locally)

---

## **🔧 Setup & Installation**

### **1️⃣ Clone the Repository**

```bash
git clone https://github.com/Funminaima/weather-dashboard-s3.git
cd weather-dashboard-s3
```

### **2️⃣ Set Up Environment Variables**

Create a `.env` file and add:

```ini
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
OPENWEATHER_API_KEY=your-openweather-api-key
AWS_BUCKET_NAME=your-s3-bucket-name
```

### **3️⃣ Deploy Infrastructure using Terraform**

## Note that the terraform code also helps build and push your image to ecr ✅

```bash
cd terraform
terraform init
terraform apply -auto-approve
```

After deployment, Terraform will output the **ALB URL**.

---

## **🌎 Accessing the Application**

Once Terraform deployment is complete, visit:

```bash
http://<alb-dns-name>
```

---

## **📊 Monitoring & Debugging**

### **1️⃣ Check ECS Task Status**

```bash
aws ecs list-tasks --cluster python-weather-dashboard
aws ecs describe-tasks --cluster python-weather-dashboard --tasks <task-id>
```

### **2️⃣ View CloudWatch Logs**

```bash
aws logs tail /ecs/python-weather-dashboard
```

### **3️⃣ Check ALB Target Group Health**

```bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

---

## **📌 Troubleshooting**

| Issue                                   | Solution                                                                      |
| --------------------------------------- | ----------------------------------------------------------------------------- |
| ALB returns **503 Service Unavailable** | Check if ECS tasks are running and healthy. Verify target group registration. |
| ECS task keeps stopping                 | Run `aws logs tail /ecs/python-weather-dashboard` to debug errors.            |
| Terraform fails due to ECR issues       | Manually push the Docker image before Terraform applies.                      |

---

## **💡 Future Improvements**

✅ Add Redis caching for API responses
✅ Enhance UI with React.js frontend
✅ Improve ALB logging and security settings

**🎉 Happy Coding! 🚀**
