import argparse
import socket
import threading
import time


def receive_messages(port=65000, host='0.0.0.0'):
    # Create a UDP socket for receiving
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Bind to the specified port
        sock.bind((host, port))
        print(f"Listening for messages on {host}:{port}")
        
        while True:
            try:
                data, addr = sock.recvfrom(1024)
                print(f"Received from {addr}: {data.decode()}")
            except Exception as e:
                print(f"Error receiving: {e}")
                break
    finally:
        sock.close()


def send_udp_message(message, port=65001, host='127.0.0.1'):
    # Create an IPv4 UDP socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        # Send the message
        bytes_sent = sock.sendto(message.encode(), (host, port))
        print(f"Sent {bytes_sent} bytes to {host}:{port}: {message}")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        sock.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='UDP Communication Tool')
    parser.add_argument('--target-ip', default='127.0.0.1',
                      help='Target IP address (default: 127.0.0.1)')
    parser.add_argument('--target-port', type=int, default=65001,
                      help='Target port (default: 65001)')
    parser.add_argument('--listen-port', type=int, default=65000,
                      help='Listen port (default: 65000)')
    
    args = parser.parse_args()
    
    print(f"Starting UDP test...")
    print(f"Target device: {args.target_ip}:{args.target_port}")
    print(f"Listening on port: {args.listen_port}")
    
    # Start receiver thread
    receiver_thread = threading.Thread(
        target=receive_messages, 
        kwargs={'port': args.listen_port, 'host': '0.0.0.0'},
        daemon=True
    )
    receiver_thread.start()
    
    # Test messages
    messages = [
        "Hello Flutter UDP",
        "Testing 123",
        "Message from Python"
    ]
    
    try:
        for msg in messages:
            send_udp_message(msg, port=args.target_port, host=args.target_ip)
            time.sleep(2)  # Wait 2 seconds between messages
        
        # Keep the script running to continue receiving messages
        print("\nKeeping receiver alive. Press Ctrl+C to exit...")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\nExiting...")