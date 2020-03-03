from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello_cloud():
    return 'Ki Flask app: listening on 5000,  provisioned via terraform and configured via salt - Hello Google Cloud!'
app.run(host='0.0.0.0', port='5000')
