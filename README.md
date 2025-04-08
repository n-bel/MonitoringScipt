# 🖥️ PowerShell Metrics Exporter for Prometheus

## 📘 Overview

This project is a PowerShell-based script designed to **retrieve system data based on dynamic criteria** defined in a JSON configuration file. It then **exposes the gathered metrics through a local server endpoint**, allowing **Prometheus** to scrape and monitor the data efficiently.

### 🔍 How It Works

1. **Configuration Input**:  
   The script reads a JSON file that defines which system metrics or properties to collect (e.g., CPU usage, memory stats, service status).

2. **Data Collection**:  
   Based on the criteria from the JSON file, the script queries the local system for the relevant information.

3. **Prometheus Integration**:  
   A simple server (running via PowerShell) listens for incoming HTTP requests (e.g., from Prometheus) and returns the latest collected metrics in a Prometheus-friendly format.

---

## ✅ Features

- Dynamic data collection based on external JSON configuration
- Lightweight PowerShell implementation
- Easily pluggable with Prometheus for real-time system monitoring

---

## 🛠️ TODO

- [ ] **Parse JSON configuration** to support dynamic metric definitions
- [ ] **Modularize the script**: break into functions or modules for better reusability and maintenance
- [ ] **Add logging**: implement a basic logging mechanism for troubleshooting

---

## 🚀 Getting Started

Coming soon : setup instructions, will be added once the base features are complete.