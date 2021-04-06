 # Copies the index.html file to the webserver instance
  provisioner "file" {
    source      = "index.html"
    destination = "/home/ubuntu/index.html"
  }

  # Install Python and run SimpleHTTPServer on port 80
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -qq",
      "sudo apt install -y python",
      "python -m SimpleHTTPServer 80 &",
      "python -m SimpleHTTPServer 8000 &",
    ]
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("key")
  }
