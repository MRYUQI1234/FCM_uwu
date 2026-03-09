import json
import struct
import sys

def dump_gltf_hierarchy(glb_path):
    with open(glb_path, 'rb') as f:
        magic = f.read(4)
        if magic != b'glTF':
            print("Not a GLB file")
            return
        version, length = struct.unpack('<II', f.read(8))
        chunk_length, chunk_type = struct.unpack('<II', f.read(8))
        if chunk_type != 0x4E4F534A: # JSON
            print("First chunk is not JSON")
            return
        json_data = f.read(chunk_length).decode('utf-8')
        gltf = json.loads(json_data)
        
        nodes = gltf.get('nodes', [])
        scenes = gltf.get('scenes', [])
        
        def print_node(node_idx, depth=0):
            if node_idx >= len(nodes):
                return
            node = nodes[node_idx]
            name = node.get('name', f'Node_{node_idx}')
            print('  ' * depth + f"- {name} (ID: {node_idx})")
            for child_idx in node.get('children', []):
                print_node(child_idx, depth + 1)
        
        for scene in scenes:
            print(f"Scene: {scene.get('name', 'Default')}")
            for node_idx in scene.get('nodes', []):
                print_node(node_idx, 1)

if __name__ == '__main__':
    dump_gltf_hierarchy(sys.argv[1])
