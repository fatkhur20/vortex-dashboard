import sys, os
path = sys.argv[1]
m = open(path).read()
perms = '''    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
'''
m = m.replace('<application', perms + '<application')

token = os.environ.get('MAPBOX_ACCESS_TOKEN', '')
if token:
    meta = '''    <meta-data android:name="com.mapbox.token" android:value="''' + token + '''"/>
'''
    m = m.replace('<application', meta + '<application')

m = m.replace('android:label="vortex_dashboard"', 'android:label="Vortex Dashboard"')
open(path, 'w').write(m)
print('Patched:', path)
