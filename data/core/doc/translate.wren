import "core/config" for Config

class Translate {
  static is_non_word(char) {
    // TODO(thacuber2a03): not everything is a word
    return false
  }

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
