echo $#    

BUILD_TYPE=Debug
for argv in $@
do
  if [ "$argv" == "release" ]
  then
    BUILD_TYPE=Release
    echo "build a release version"
  fi
done

if [ "$BUILD_TYPE" == "Debug" ]
then
  echo "build a debug version"
fi

export CC=/usr/bin/clang
export CXX=/usr/bin/clang++

for argv in $@    
do    
  if [ "$argv" == "clean" ]    
  then                               
    rm -rf build           
    break    
  fi    
done    
    
mkdir -p build && cd build    
cmake -DCMAKE_BUILD_TYPE=$BUILD_TYPE -G Ninja ..    
cp compile_commands.json ..    
ninja -j10
    
for argv in $@    
do    
  if [ "$argv" == "test" ]    
  then    
    make check-tests    
    break    
  fi    
done    
    
for argv in $@    
do    
  if [ "$argv" == "check" ]     
  then    
    make format    
    make check-lint    
    make check-clang-tidy    
    break    
  fi    
done
