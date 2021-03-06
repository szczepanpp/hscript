@echo off
rm -rf release
mkdir release
cp haxelib.json README.md extraParams.hxml release
cd release
mkdir hscript
cd ..
cp hscript/*.hx release/hscript
cd release
mkdir script
cp script/*.hx* release/script
cd release/script
haxe build.hxml
cd ../..
haxe -xml release/haxedoc.xml hscript.Interp hscript.Parser hscript.Bytes hscript.Macro
7z a -tzip release.zip release
rm -rf release
haxelib submit release.zip
pause