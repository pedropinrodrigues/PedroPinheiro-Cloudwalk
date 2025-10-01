import requests

data = requests.get('http://127.0.0.1:8090/export').json()

users = data.get('users', [])
notifications = data.get('notifications', [])

print(type(notifications[0]['created_at']))