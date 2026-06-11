while IFS= read -r dir; do
  case ":$PATH:" in
    *":$dir:"*) ;;
    *) PATH="$PATH:$dir" ;;
  esac
done < <(find "$HOME/.local/bin" -type d)
export PATH
