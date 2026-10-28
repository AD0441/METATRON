#!/usr/bin/env python3
"""Recreate the app project; SwiftPM remains the core, CLI and test entry point."""
from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parent.parent
objects={}
def uid(name):return hashlib.sha1(name.encode()).hexdigest()[:24].upper()
def add(identity,isa,**fields):
 key=uid(identity);objects[key]=dict(isa=isa,**fields);return key
def ref(path,kind):return add("file:"+path,"PBXFileReference",lastKnownFileType=kind,path=path,sourceTree="<group>")
sources=[];resources=[];children=[]
for path in sorted((root/"Sources/Metatron").rglob("*.swift")):
 name=str(path.relative_to(root));file=ref(name,"sourcecode.swift");children.append(file)
 sources.append(add("build:"+name,"PBXBuildFile",fileRef=file))
for name,kind in [("Resources/AppIcon.icns","image.icns"),("LICENSE","text")]:
 file=ref(name,kind);children.append(file);resources.append(add("build:"+name,"PBXBuildFile",fileRef=file))
product=add("product","PBXFileReference",explicitFileType="wrapper.application",includeInIndex="0",path="METATRON.app",sourceTree="BUILT_PRODUCTS_DIR")
products=add("products","PBXGroup",children=[product],name="Products",sourceTree="<group>")
main=add("main","PBXGroup",children=children+[products],sourceTree="<group>")
package=add("package","XCLocalSwiftPackageReference",relativePath=".")
dependencies=[];frameworks=[]
for name in ["MetatronCore","MetatronWorkflow"]:
 dep=add("dependency:"+name,"XCSwiftPackageProductDependency",productName=name);dependencies.append(dep)
 frameworks.append(add("framework:"+name,"PBXBuildFile",productRef=dep))
src=add("sources","PBXSourcesBuildPhase",buildActionMask="2147483647",files=sources,runOnlyForDeploymentPostprocessing="0")
res=add("resources","PBXResourcesBuildPhase",buildActionMask="2147483647",files=resources,runOnlyForDeploymentPostprocessing="0")
libs=add("frameworks","PBXFrameworksBuildPhase",buildActionMask="2147483647",files=frameworks,runOnlyForDeploymentPostprocessing="0")
projectConfigs=[];targetConfigs=[]
for config in ["Debug","Release"]:
 projectConfigs.append(add("project:"+config,"XCBuildConfiguration",buildSettings={"MACOSX_DEPLOYMENT_TARGET":"14.0","SDKROOT":"macosx","SWIFT_VERSION":"6.0"},name=config))
 settings={"ONLY_ACTIVE_ARCH":"YES","ALWAYS_SEARCH_USER_PATHS":"NO","CLANG_ENABLE_MODULES":"YES","PRODUCT_BUNDLE_IDENTIFIER":"local.metatron.app","PRODUCT_NAME":"METATRON","PRODUCT_MODULE_NAME":"Metatron","INFOPLIST_FILE":"Resources/Info.plist","GENERATE_INFOPLIST_FILE":"NO","SWIFT_DEFAULT_ACTOR_ISOLATION":"MainActor","SWIFT_UPCOMING_FEATURE_NONISOLATED_NONSENDING_BY_DEFAULT":"YES","CODE_SIGNING_ALLOWED":"NO","ENABLE_APP_SANDBOX":"NO","SWIFT_OPTIMIZATION_LEVEL":"-O" if config=="Release" else "-Onone","MARKETING_VERSION":"2.2.0","CURRENT_PROJECT_VERSION":"4","LD_RUNPATH_SEARCH_PATHS":["$(inherited)","@executable_path/../Frameworks"]}
 targetConfigs.append(add("target:"+config,"XCBuildConfiguration",buildSettings=settings,name=config))
projectList=add("projectConfig","XCConfigurationList",buildConfigurations=projectConfigs,defaultConfigurationIsVisible="0",defaultConfigurationName="Release")
targetList=add("targetConfig","XCConfigurationList",buildConfigurations=targetConfigs,defaultConfigurationIsVisible="0",defaultConfigurationName="Release")
target=add("target","PBXNativeTarget",buildConfigurationList=targetList,buildPhases=[src,libs,res],buildRules=[],dependencies=[],name="METATRON",packageProductDependencies=dependencies,productName="METATRON",productReference=product,productType="com.apple.product-type.application")
project=add("project","PBXProject",attributes={"LastUpgradeCheck":"2700"},buildConfigurationList=projectList,compatibilityVersion="Xcode 14.0",developmentRegion="es",hasScannedForEncodings="0",knownRegions=["es","en","Base"],mainGroup=main,packageReferences=[package],productRefGroup=products,projectDirPath="",projectRoot="",targets=[target])
def encode(v):
 if isinstance(v,dict):return "{\n"+"\n".join(f"{json.dumps(k)} = {encode(value)};" for k,value in v.items())+"\n}"
 if isinstance(v,list):return "("+",".join(encode(x) for x in v)+")"
 return json.dumps(v,ensure_ascii=False)
folder=root/"METATRON.xcodeproj";folder.mkdir(exist_ok=True)
(folder/"project.pbxproj").write_text("// !$*UTF8*$!\n"+encode(dict(archiveVersion="1",classes={},objectVersion="56",objects=objects,rootObject=project))+"\n")
scheme=folder/"xcshareddata/xcschemes";scheme.mkdir(parents=True,exist_ok=True)
(scheme/"METATRON.xcscheme").write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="METATRON.app" BlueprintName="METATRON" ReferencedContainer="container:METATRON.xcodeproj"/></BuildActionEntry></BuildActionEntries></BuildAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{target}" BuildableName="METATRON.app" BlueprintName="METATRON" ReferencedContainer="container:METATRON.xcodeproj"/></BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release"/><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>
''')
print(folder)
