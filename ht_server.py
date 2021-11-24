import asyncio
import threading
import json
from typing import List

import cv2
import mediapipe as mp


ht = None


class CHandTracking(object):
    th: threading.Thread
    th_lock: threading.Lock
    th_event: threading.Event
    list_hands: List

    def __init__(self):
        self.th_lock = threading.Lock()
        self.th_event = threading.Event()
        self.th_event.clear()

        self.list_hands = []

    def get_hands(self):
        self.th_lock.acquire(1)
        list_result = self.list_hands.copy()
        self.th_lock.release()

        return list_result

    def runner(self):
        mp_hands = mp.solutions.hands

        cap = cv2.VideoCapture(0)

        with mp_hands.Hands(
            model_complexity=0,
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5,
        ) as hands:

            while True:
                if cap.isOpened() is False:
                    break
                if self.th_event.is_set() is True:
                    break

                success, image = cap.read()
                if not success:
                    continue

                image.flags.writeable = False
                image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
                results = hands.process(image)

                self.list_hands = []

                if results.multi_hand_landmarks:

                    self.th_lock.acquire(1)

                    for hand_landmarks in results.multi_hand_landmarks:
                        list_landmark = [
                            {
                                "x": landmark.x,
                                "y": landmark.y,
                                "z": landmark.z,
                            }
                            for landmark in hand_landmarks.landmark
                        ]
                        self.list_hands.append(list_landmark)

                    self.th_lock.release()

        cap.release()

    def init(self):
        self.th = threading.Thread(target=self.runner)
        self.th.start()

    def term(self):
        self.th_event.set()
        self.th.join()


class UDPProtocol(object):
    def connection_made(self, transport):
        self.transport = transport

    def datagram_received(self, data, addr):
        global ht
        txt = json.dumps(ht.get_hands())
        self.transport.sendto(txt.encode("utf-8"), addr)

    def connection_lost(self, exc):
        pass


async def main():

    lp = asyncio.get_running_loop()

    transport, protocol = await lp.create_datagram_endpoint(
        lambda: UDPProtocol(), local_addr=("127.0.0.1", 8000)
    )

    await asyncio.sleep(1 * 60 * 60)

    transport.close()


if __name__ == "__main__":

    ht = CHandTracking()
    ht.init()

    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass

    ht.term()
