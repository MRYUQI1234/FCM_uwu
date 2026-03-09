import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main() async {
  try {
    final file = File('assets/models/VivornFinal8.4.glb');
    final bytes = await file.readAsBytes();
    
    // GLB format:
    // Magic: 4 bytes ("glTF")
    // Version: 4 bytes
    // Length: 4 bytes
    // Chunk 0 Length: 4 bytes
    // Chunk 0 Type: 4 bytes ("JSON")
    // Chunk 0 Data: [Chunk 0 Length] bytes
    
    final magic = utf8.decode(bytes.sublist(0, 4));
    if (magic != 'glTF') throw 'Not a GLB file';
    
    final byteData = ByteData.sublistView(bytes);
    final jsonChunkLength = byteData.getUint32(12, Endian.little);
    
    final jsonChunkType = utf8.decode(bytes.sublist(16, 20));
    if (jsonChunkType != 'JSON') throw 'First chunk is not JSON';
    
    final jsonStr = utf8.decode(bytes.sublist(20, 20 + jsonChunkLength));
    final jsonMap = jsonDecode(jsonStr);
    
    final nodes = jsonMap['nodes'] as List<dynamic>;
    
    final names = <String>{};
    for (final node in nodes) {
      if (node['name'] != null) {
        names.add(node['name']);
      }
    }
    
    final sortedNames = names.toList()..sort();
    
    final outFile = File('node_names_extracted.txt');
    await outFile.writeAsString(sortedNames.join('\n'));
    
    print('Extracted ${sortedNames.length} names.');
    
  } catch (e) {
    print('Error: \$e');
  }
}
