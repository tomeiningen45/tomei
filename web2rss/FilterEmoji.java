import java.io.*;

public class FilterEmoji {
  public static void main(String args[]) {
    try {
      BufferedReader buffer = new BufferedReader(new InputStreamReader(System.in, "UTF-8"));
      BufferedWriter out = new BufferedWriter(new OutputStreamWriter(System.out, "UTF-8"));
      String line;
      while ((line = buffer.readLine()) != null) {
        for (int i = 0; i < line.length(); i++) {
          char c = line.charAt(i);
          if (0x0000 <= c && c <= 0x0008) {
            c = '?'; // ascii control chars
          }
          else if (0xD800 <= c && c <= 0xDFFF) {
            c = '?';  // surrogates
          }
          out.write(c);
        }
        out.write("\n");
      }
      out.close();
      System.exit(0);
    } catch (Throwable t) {}
  }
}
