import sys

fcm_path = r'd:\FCM\frontend\fcm_app\lib\features\resident\presentation\views\resident_home_view.dart'
git_path = r'd:\FCM\Git\lib\features\resident\presentation\views\resident_home_view.dart'

with open(fcm_path, 'r', encoding='utf-8') as f:
    fcm_content = f.read()

with open(git_path, 'r', encoding='utf-8') as f:
    git_content = f.read()

# Extract from fcm_app
# 1. _handleObjectClick
start_handle = fcm_content.find('  void _handleObjectClick(dynamic rawData) {')
end_handle = fcm_content.find('  void _closePopup() {')
if start_handle == -1 or end_handle == -1:
    print('Failed to find _handleObjectClick in fcm_app', file=sys.stderr)
    sys.exit(1)
fcm_handle = fcm_content[start_handle:end_handle]

# 2. _formatObjectName
start_format = fcm_content.find('  String _formatObjectName(String rawName) {')
end_format = fcm_content.find('  void _handleObjectClick(dynamic rawData) {')
if start_format == -1 or end_format == -1:
    print('Failed to find _formatObjectName in fcm_app', file=sys.stderr)
    sys.exit(1)
fcm_format = fcm_content[start_format:end_format]

# 3. JS Interop Block
start_js = fcm_content.find('    // ── JS INTEROP: V13.0 Flex-Match & Debug Bridge ──')
end_js = fcm_content.find('  String _formatObjectName(String rawName) {')
if start_js == -1 or end_js == -1:
    print('Failed to find JS Interop Block in fcm_app', file=sys.stderr)
    sys.exit(1)
fcm_js = fcm_content[start_js:end_js].strip()

# Now find targets in git_content
g_start_handle = git_content.find('  void _handleObjectClick(dynamic rawData) {')
g_end_handle = git_content.find('  String _formatObjectName(String rawName) {')
if g_start_handle == -1 or g_end_handle == -1:
    print('Failed to find _handleObjectClick in Git', file=sys.stderr)
    sys.exit(1)

g_start_format = git_content.find('  String _formatObjectName(String rawName) {')
g_end_format = git_content.find('  // Sample announcements')
if g_start_format == -1 or g_end_format == -1:
    print('Failed to find _formatObjectName in Git', file=sys.stderr)
    sys.exit(1)

g_start_js = git_content.find('  void _setupJsInterop() {')
g_end_js = git_content.find('  @override\n  void dispose() {')
if g_start_js == -1 or g_end_js == -1:
    print('Failed to find _setupJsInterop in Git', file=sys.stderr)
    sys.exit(1)

# Construct new Git content
new_git_content = (
    git_content[:g_start_handle] +
    fcm_handle +
    fcm_format +
    git_content[g_end_format:g_start_js] +
    '  void _setupJsInterop() {\n    ' +
    fcm_js +
    '\n  }\n\n' +
    git_content[g_end_js:]
)

with open(git_path, 'w', encoding='utf-8') as f:
    f.write(new_git_content)

print('Updated resident_home_view.dart successfully.')
