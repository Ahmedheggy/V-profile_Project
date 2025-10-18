# Step 1: Use a lightweight official base image
FROM python:3.11-s

# Step 2: Set working directory
WORKDIR /app

# Step 3: Copy and install dependencies first (use caching)
COPY requirements.txt /app
RUN pip install --no-cache-dir -r requirements.txt

# Step 4: Copy the Flask app code
COPY app.py /app

# Step 5: Expose Flask default port
EXPOSE 5000

# Step 6: Run the app
CMD ["python", "app.py"]
