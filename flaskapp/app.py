from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/')
def hello_world():
    message = {"message": "Hello, World!"}
    return jsonify(message)

if __name__ == '__main__':
    app.run(debug=True)
