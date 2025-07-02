rm idlist
touch idlist

for i in {0..8999}; do
  if [[ $((i + 1000)) -eq 2899 ]]; then
    continue
  fi
  echo $((i + 1000))':' >> idlist
done
