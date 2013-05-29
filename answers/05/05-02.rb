result = <<-EOT
PHD Comics: http://www.phdcomics.com/comics.php
Dilbert: http://dilbert.com
Chicken Strip: http://chickenstrip.wordpress.com/
XKCD: http://xkcd.com/
EOT
File.read("/Home/komik.txt") == result.strip