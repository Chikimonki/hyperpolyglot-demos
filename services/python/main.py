from flask import Flask, jsonify, request
import ctypes
import os

app = Flask(__name__)

# Load Zig library
lib_path = os.path.join(os.path.dirname(__file__), 'libmathcore.so')
ziglib = ctypes.CDLL(lib_path)
ziglib.fibonacci.argtypes = [ctypes.c_uint32]
ziglib.fibonacci.restype = ctypes.c_uint64
ziglib.is_prime.argtypes = [ctypes.c_uint64]
ziglib.is_prime.restype = ctypes.c_bool

@app.route('/health')
def health():
    return jsonify({"status": "healthy", "service": "python-compute"})

@app.route('/api/fibonacci/<int:n>')
def fibonacci(n):
    if n > 90:
        return jsonify({"error": "n too large (max 90)"}), 400
    result = ziglib.fibonacci(n)
    return jsonify({"n": n, "fibonacci": int(result), "computed_by": "zig-kernel"})

@app.route('/api/primes', methods=['POST'])
def find_primes():
    data = request.get_json()
    start = data.get('start', 1)
    end = data.get('end', 100)
    if end - start > 10000:
        return jsonify({"error": "range too large"}), 400
    primes = [n for n in range(start, end + 1) if ziglib.is_prime(n)]
    return jsonify({"range": [start, end], "count": len(primes), "primes": primes[:100]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
