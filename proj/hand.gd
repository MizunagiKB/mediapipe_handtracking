extends Spatial


const HAND_NODE_SIZE: int = 21

const list_handline: Array = [
    [0, 1], [1, 2], [2, 3], [3, 4],
    [5, 6], [6, 7], [7, 8],
    [9, 10], [10, 11], [11, 12],
    [13, 14], [14, 15], [15, 16],
    [17, 18], [18, 19], [19, 20],
    [2, 5], [5, 9], [9, 13], [13, 17], [17, 0]
]
var mat_hand0: SpatialMaterial
var mat_hand1: SpatialMaterial
var mat_line :SpatialMaterial
var list_hand_node: Array


func _ready():

    mat_hand0 = SpatialMaterial.new()
    mat_hand0.albedo_color = Color.white

    mat_hand1 = SpatialMaterial.new()
    mat_hand1.albedo_color = Color.red

    mat_line = SpatialMaterial.new()
    mat_line.albedo_color = Color.white

    for idx in range(HAND_NODE_SIZE):
        var o = CSGSphere.new()

        if idx in [4, 8, 12, 16, 20]:
            o.material_override = mat_hand1
            o.radius = 0.75
        else:
            o.material_override = mat_hand0
            o.radius = 0.5

        $root.add_child(o)
        list_hand_node.append(o)

    $ImmediateGeometry.material_override = mat_line


func update(list_node: Array):

    var list_vct: Array = []

    var aspect = OS.window_size.x / OS.window_size.y

    for v in list_node:
        list_vct.append(
            Vector3((v.x - 0.5) * aspect, (v.y - 0.5), (v.z - 0.5)) * -50
        )

    var idx: int = 0

    for v in list_vct:
        var obj = list_hand_node[idx]
        obj.translation = v

        idx += 1

    $ImmediateGeometry.clear()
    $ImmediateGeometry.begin(Mesh.PRIMITIVE_LINES)

    for line_pair in list_handline:
        $ImmediateGeometry.add_vertex(list_vct[line_pair[0]])
        $ImmediateGeometry.add_vertex(list_vct[line_pair[1]])

    $ImmediateGeometry.end()
