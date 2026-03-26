from flask import Flask, jsonify, request
import ctypes, os

app = Flask(__name__)
lib = ctypes.CDLL(os.path.join(os.path.dirname(__file__), 'libmathcore.so'))

lib.fibonacci.argtypes = [ctypes.c_uint32]
lib.fibonacci.restype = ctypes.c_uint64
lib.is_prime.argtypes = [ctypes.c_uint64]
lib.is_prime.restype = ctypes.c_bool
lib.factorial.argtypes = [ctypes.c_uint32]
lib.factorial.restype = ctypes.c_uint64
lib.hash_djb2.argtypes = [ctypes.c_char_p, ctypes.c_size_t]
lib.hash_djb2.restype = ctypes.c_uint64

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "python"})

@app.route('/api/fibonacci/<int:n>')
def fibonacci(n):
    if n > 90: return jsonify({"error": "too large"}), 400
    return jsonify({"n": n, "result": int(lib.fibonacci(n))})

@app.route('/api/factorial/<int:n>')
def factorial(n):
    if n > 20: return jsonify({"error": "too large"}), 400
    return jsonify({"n": n, "result": int(lib.factorial(n))})

@app.route('/api/hash', methods=['POST'])
def hash_text():
    text = request.json.get('text', '')
    return jsonify({"hash": int(lib.hash_djb2(text.encode(), len(text)))})

@app.route('/api/primes', methods=['POST'])
def primes():
    data = request.json
    start, end = data.get('start', 1), data.get('end', 100)
    result = [n for n in range(start, end+1) if lib.is_prime(n)]
    return jsonify({"count": len(result), "primes": result[:100]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
