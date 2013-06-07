# Mengenal Ruby

Untuk menjalankan server:

```
bundle
ruby app.ruby -p 4000
```

Contoh:

```
curl -XPOST http://localhost:4000 -d "snippet=`cat input.rb`"
curl -XPOST http://localhost:4000 -d "snippet=`cat input.rb`" -d "snippet_name=testing"
```

