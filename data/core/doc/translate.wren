import "core/config" for Config
import "core/common" for Common

class Translate {
  static is_non_word(char) {
    // TODO(thacuber2a03): not everything is a word
    return false
  }

  static previous_char { Fn.new { |doc, pos, rest|
    var loop = true
    while (loop) {
      pos = doc.position_offset(pos, [-1])
      loop = Common.is_utf8_cont(doc.get_char(pos))
    }
    return pos
  } }

  static next_char { Fn.new { |doc, pos, rest|
    var loop = true
    while (loop) {
      pos = doc.position_offset(pos, [1])
      loop = Common.is_utf8_cont(doc.get_char(pos))
    }
    return pos
  } }

  static start_of_word(doc, pos) {
    while (true) {
      var pos2 = doc.position_offset(pos, [-1])
      var char = doc.get_char(pos2)
      if (is_non_word(char) || pos == pos2) break
      pos = pos2
    }
    return pos
  }

  static end_of_word(doc, pos) {
    while (true) {
      var pos2 = doc.position_offset(pos, [1])
      var char = doc.get_char(pos2)
      if (is_non_word(char) || pos == pos2) break
      pos = pos2
    }
    return pos
  }
}
