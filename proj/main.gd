extends Spatial


var peer_udp: PacketPeerUDP
var list_hand_instance: Array = []
var list_hand_pose: Array = []


func _ready():
    
    peer_udp = PacketPeerUDP.new()
    peer_udp.connect_to_host("127.0.0.1", 8000)

    var cls = load("res://hand.tscn")
    for idx in range(2):
        var o = cls.instance()
        add_child(o)
        list_hand_instance.append(o)


func _process(delta: float):

    if peer_udp.get_available_packet_count() == 0:
        var buf = PoolByteArray([0])
        peer_udp.put_packet(buf)
    else:
        var data = peer_udp.get_packet()

        if data.size() > 0:
            var res = JSON.parse(data.get_string_from_utf8())

            if res.error == OK:
                list_hand_pose = res.result

                for n in range(2):
                    list_hand_instance[n].visible = false

                var idx: int = 0
                for hand in list_hand_pose:
                    list_hand_instance[idx].update(hand)
                    list_hand_instance[idx].visible = true
                    idx += 1
