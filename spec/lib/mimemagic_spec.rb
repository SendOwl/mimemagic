# frozen_string_literal: true

require "rspec"
require "mimemagic"
require "stringio"
require "forwardable"

RSpec.describe "MimeMagic" do
  it "should have type, mediatype and subtype" do
    expect(MimeMagic.new("text/html").type).to eq "text/html"
    expect(MimeMagic.new("text/html").mediatype).to eq "text"
    expect(MimeMagic.new("text/html").subtype).to eq "html"
  end

  it "should have mediatype helpers" do
    expect(MimeMagic.new("text/plain")).to be_text
    expect(MimeMagic.new("text/html")).to be_text
    expect(MimeMagic.new("application/xhtml+xml")).to be_text
    expect(MimeMagic.new("application/octet-stream")).not_to be_text
    expect(MimeMagic.new("image/png")).not_to be_text
    expect(MimeMagic.new("image/png")).to be_image
    expect(MimeMagic.new("video/ogg")).to be_video
    expect(MimeMagic.new("audio/mpeg")).to be_audio
  end

  it "should have hierarchy" do
    expect(MimeMagic.new("text/html")).to be_child_of "text/plain"
    expect(MimeMagic.new("text/x-java")).to be_child_of "text/plain"
  end

  it "should have extensions" do
    expect(MimeMagic.new("text/html").extensions).to eq %w[htm html]
  end

  it "should have comment" do
    expect(MimeMagic.new("text/html").comment).to eq "HTML document"
  end

  it "should recognize extensions" do
    expect(MimeMagic.by_extension(".html")).to eq "text/html"
    expect(MimeMagic.by_extension("html")).to eq "text/html"
    expect(MimeMagic.by_extension(:html)).to eq "text/html"
    expect(MimeMagic.by_extension("rb")).to eq "application/x-ruby"
    expect(MimeMagic.by_extension("crazy")).to be_nil
    expect(MimeMagic.by_extension("")).to be_nil
  end

  it "should recognize by a path" do
    expect(MimeMagic.by_path("/adsjkfa/kajsdfkadsf/kajsdfjasdf.html")).to eq "text/html"
    expect(MimeMagic.by_path("something.html")).to eq "text/html"
    expect(MimeMagic.by_path("wtf.rb")).to eq "application/x-ruby"
    expect(MimeMagic.by_path("where/am.html/crazy")).to be_nil
    expect(MimeMagic.by_path("")).to be_nil
  end

  it "should recognize xlsx as zip without overlay" do
    file = "spec/fixtures/files/application.vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    expect(MimeMagic.by_magic(File.read(file))).to eq "application/zip"
    expect(MimeMagic.by_magic(File.open(file, "rb"))).to eq "application/zip"
  end

  it "should recognize xlsm with overlay, but only if we can see the file path" do
    require "mimemagic/overlay"

    file = "spec/fixtures/bad_magic_files/sample.xlsm"
    expect(MimeMagic.by_magic(File.read(file))).to eq "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    expect(MimeMagic.by_magic(File.open(file, "rb"))).to eq "application/vnd.ms-excel.sheet.macroEnabled.12"
  end

  it "should recognize pptx with overlay, but only if we can see the file path" do
    require "mimemagic/overlay"

    file = "spec/fixtures/bad_magic_files/sample.pptx"
    expect(MimeMagic.by_magic(File.read(file))).to eq "application/zip"
    expect(MimeMagic.by_magic(File.open(file,
                                        "rb"))).to eq "application/vnd.openxmlformats-officedocument.presentationml.presentation"
  end

  it "should recognize a weirdly formatted pptx with overlay, but only if we can see the file path" do
    require "mimemagic/overlay"

    file = "spec/fixtures/bad_magic_files/sample.pptx"
    expect(MimeMagic.by_magic(File.read(file))).to eq "application/zip"
    expect(MimeMagic.by_magic(File.open(file,
                                        "rb"))).to eq "application/vnd.openxmlformats-officedocument.presentationml.presentation"
  end

  it "should recognize by magic" do
    require "mimemagic/overlay"
    Dir["spec/fixtures/files/*"].each do |file|
      expected = File.split(file).last.sub(".", "/")
      actual = MimeMagic.by_magic(File.read(file))
      expect(actual).to eq(expected),
                        "contents: #{file} is not #{expected}, it's #{actual}. This can happen if you add a file to spec/fixtures/files and the detection code relies on the file extension and your file does not have one"
      actual_bin = MimeMagic.by_magic(File.open(file, "rb"))
      expect(actual_bin).to eq(expected),
                            "file: #{file} is not #{expected}, it's #{actual_bin}. This can happen if you add a file to spec/fixtures/files and the detection code relies on the file extension and your file does not have one"
    end
  end

  it "should recognize wolfram cdf files" do
    require "mimemagic/overlay"
    file = "spec/fixtures/bad_magic_files/sample.cdf"
    expect(MimeMagic.by_magic(File.read(file))).to eq "application/vnd.wolfram.cdf.text"
  end

  it "should recognize Adobe digital negatives (dng)" do
    require "mimemagic/overlay"
    file = "spec/fixtures/bad_magic_files/sample.dng"
    expect(MimeMagic.by_magic(File.read(file))).to eq "image/x-adobe-dng"
  end

  it "should recognize xmp" do
    require "mimemagic/overlay"
    file = "spec/fixtures/bad_magic_files/sample.xmp"
    expect(MimeMagic.by_magic(File.read(file))).to eq "application/octet-stream"
  end

  it "should recognize an Anki apkg file" do
    require "mimemagic/overlay"
    file = "spec/fixtures/bad_magic_files/sample.apkg"
    expect(MimeMagic.by_magic(File.read(file))).to eq "application/octet-stream"
  end

  it "should recognize all by magic" do
    require "mimemagic/overlay"
    file = "spec/fixtures/files/application.vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    mimes = %w[application/vnd.openxmlformats-officedocument.spreadsheetml.sheet application/zip]
    expect(MimeMagic.all_by_magic(File.read(file)).map(&:type)).to eq mimes
  end

  it "should have add" do
    MimeMagic.add("application/mimemagic-test",
                  extensions: %w[ext1 ext2],
                  parents: "application/xml",
                  comment: "Comment")
    expect(MimeMagic.by_extension("ext1")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_extension("ext2")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_extension("ext2").comment).to eq "Comment"
    expect(MimeMagic.new("application/mimemagic-test").extensions).to eq %w[ext1 ext2]
    expect(MimeMagic.new("application/mimemagic-test")).to be_child_of "text/plain"
  end

  it "should process magic" do
    MimeMagic.add("application/mimemagic-test",
                  magic: [[0, "MAGICTEST"], # MAGICTEST at position 0
                          [1, "MAGICTEST"], # MAGICTEST at position 1
                          [9..12, "MAGICTEST"], # MAGICTEST starting at position 9 to 12
                          [2, "MAGICTEST", [[0, "X"], [0, "Y"]]]]) # MAGICTEST at position 2 and (X at 0 or Y at 0)

    expect(MimeMagic.by_magic("MAGICTEST")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic("XMAGICTEST")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(" MAGICTEST")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic("123456789MAGICTEST")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic("123456789ABMAGICTEST")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic("123456789ABCMAGICTEST")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic("123456789ABCDMAGICTEST")).to be_nil
    expect(MimeMagic.by_magic("X MAGICTEST")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic("Y MAGICTEST")).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic("Z MAGICTEST")).to be_nil

    expect(MimeMagic.by_magic(StringIO.new("MAGICTEST"))).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(StringIO.new("XMAGICTEST"))).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(StringIO.new(" MAGICTEST"))).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(StringIO.new("123456789MAGICTEST"))).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(StringIO.new("123456789ABMAGICTEST"))).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(StringIO.new("123456789ABCMAGICTEST"))).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(StringIO.new("123456789ABCDMAGICTEST"))).to be_nil
    expect(MimeMagic.by_magic(StringIO.new("X MAGICTEST"))).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(StringIO.new("Y MAGICTEST"))).to eq "application/mimemagic-test"
    expect(MimeMagic.by_magic(StringIO.new("Z MAGICTEST"))).to be_nil
  end

  it "should handle different file objects" do
    MimeMagic.add("application/mimemagic-test", magic: [[0, "MAGICTEST"]])
    class IOObject
      def initialize
        @io = StringIO.new("MAGICTEST")
      end

      extend Forwardable
      delegate %i[read size rewind eof? close] => :@io
    end
    expect(MimeMagic.by_magic(IOObject.new)).to eq "application/mimemagic-test"
    class StringableObject
      def to_s
        "MAGICTEST"
      end
    end
    expect(MimeMagic.by_magic(StringableObject.new)).to eq "application/mimemagic-test"
  end
end
