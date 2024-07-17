import asyncio
import socket
import soundcard as sc
import websockets
import numpy as np

host_ip = socket.gethostbyname(socket.gethostname())
port = 1010

async def audio_stream(websocket, path):
    print(f"Client connected from {websocket.remote_address}")
    print(f"Server started at ws://{host_ip}:{port}")
    with sc.get_microphone(id=str(sc.default_speaker().name), include_loopback=True).recorder(samplerate=48000) as mic:
        while True:
            data = mic.record(numframes=153600)
            int_data = (data * 32767).astype(np.int16) 
            byte_data = int_data.tobytes()
            await websocket.send(byte_data)

async def start_server():
    async with websockets.serve(audio_stream, host_ip, port):
        print(f"Server listening at ws://{host_ip}:{port}")
        await asyncio.Future()

asyncio.run(start_server())
