# frozen_string_literal: true

# Extra magic

[["application/vnd.openxmlformats-officedocument.presentationml.presentation", [[0, "PK\003\004", [[30, "[Content_Types].xml", [[0..10_000, "ppt/"]]]]]]],
 ["application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", [[0, "PK\003\004", [[30, "[Content_Types].xml", [[0..10_000, "xl/"]]]]]]],
 ["application/vnd.ms-excel.sheet.macroEnabled.12", [[0, "Something That Doesn't Exist"]]],
 ["application/vnd.openxmlformats-officedocument.wordprocessingml.document", [[0, "PK\003\004", [[30, "[Content_Types].xml", [[0..10_000, "word/"]]]]]]],
 ["application/vnd.wolfram.cdf.text", [[0, "(* Content-type: application/vnd.wolfram.cdf.text *)"]]],
 ["image/x-adobe-dng", [[0..10_000, 'dc:format="image/dng"']]],
 ["application/octet-stream", [[0, "<x:xmpmeta"]]],
 ["application/octet-stream", [[0..100, "collection.anki2"]]]].each do |magic|
  MimeMagic.add(magic[0], magic: magic[1])
end
