#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Cat's Portscanner 0.1

import socket
import threading
from queue import Queue
import tkinter as tk
from tkinter import ttk, scrolledtext
import os

class CatScanner:
    def __init__(self, master):
        self.master = master
        self.master.title("Cat's Portscanner 0.1")
        self.master.geometry("800x600")
        
        # Simple variables
        self.open_ports = []
        self.scan_active = False
        
        # Configure style
        style = ttk.Style()
        style.theme_use('clam')
        
        # Build interface
        self.build_interface()
        
    def build_interface(self):
        # Main container
        main_frame = ttk.Frame(self.master, padding="10")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Target input
        ttk.Label(main_frame, text="Target:").grid(row=0, column=0, sticky=tk.W, pady=5)
        self.target_entry = ttk.Entry(main_frame, width=30)
        self.target_entry.insert(0, "127.0.0.1")
        self.target_entry.grid(row=0, column=1, pady=5, padx=(5, 0))
        
        # Port range
        port_frame = ttk.Frame(main_frame)
        port_frame.grid(row=1, column=0, columnspan=2, pady=5, sticky=tk.W)
        
        ttk.Label(port_frame, text="Ports:").pack(side=tk.LEFT)
        self.port_start = ttk.Entry(port_frame, width=8)
        self.port_start.insert(0, "1")
        self.port_start.pack(side=tk.LEFT, padx=5)
        
        ttk.Label(port_frame, text="-").pack(side=tk.LEFT)
        self.port_end = ttk.Entry(port_frame, width=8)
        self.port_end.insert(0, "1024")
        self.port_end.pack(side=tk.LEFT, padx=5)
        
        # Scan button
        self.scan_btn = ttk.Button(main_frame, text="Start Scan", 
                                  command=self.start_scan)
        self.scan_btn.grid(row=2, column=0, columnspan=2, pady=10)
        
        # Progress bar
        self.progress = ttk.Progressbar(main_frame, mode='indeterminate')
        self.progress.grid(row=3, column=0, columnspan=2, sticky=(tk.W, tk.E), pady=5)
        
        # Results treeview
        tree_frame = ttk.Frame(main_frame)
        tree_frame.grid(row=4, column=0, columnspan=2, pady=10, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Configure grid weights
        main_frame.rowconfigure(4, weight=1)
        main_frame.columnconfigure(1, weight=1)
        
        # Treeview with scrollbar
        tree_scroll = ttk.Scrollbar(tree_frame)
        tree_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        
        self.results_tree = ttk.Treeview(tree_frame, columns=("Port", "Service", "Status"), 
                                        show="headings", yscrollcommand=tree_scroll.set)
        tree_scroll.config(command=self.results_tree.yview)
        
        self.results_tree.heading("Port", text="Port")
        self.results_tree.heading("Service", text="Service")
        self.results_tree.heading("Status", text="Status")
        
        self.results_tree.column("Port", width=80)
        self.results_tree.column("Service", width=150)
        self.results_tree.column("Status", width=100)
        
        self.results_tree.pack(fill=tk.BOTH, expand=True)
        
        # Log output
        ttk.Label(main_frame, text="Scan Log:").grid(row=5, column=0, sticky=tk.W, pady=(10, 0))
        self.log_output = scrolledtext.ScrolledText(main_frame, height=8, bg='white', fg='black')
        self.log_output.grid(row=6, column=0, columnspan=2, sticky=(tk.W, tk.E, tk.N, tk.S), pady=5)
        
    def log(self, message):
        self.log_output.insert(tk.END, message + "\n")
        self.log_output.see(tk.END)
        self.master.update_idletasks()
        
    def scan_port(self, target, port, queue):
        """Scan a single port"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(1)
            result = sock.connect_ex((target, port))
            
            if result == 0:
                try:
                    service = socket.getservbyport(port)
                except:
                    service = "Unknown"
                
                self.open_ports.append(port)
                self.results_tree.insert("", tk.END, values=(port, service, "OPEN"))
                self.log(f"Port {port}/TCP open - {service}")
            
            sock.close()
        except Exception as e:
            pass
            
        queue.put(port)
        
    def start_scan(self):
        """Start the port scan"""
        if self.scan_active:
            return
            
        target = self.target_entry.get()
        if not target:
            self.log("Error: Please enter a target")
            return
            
        try:
            start_port = int(self.port_start.get())
            end_port = int(self.port_end.get())
        except ValueError:
            self.log("Error: Invalid port range")
            return
            
        # Clear previous results
        self.open_ports = []
        for item in self.results_tree.get_children():
            self.results_tree.delete(item)
            
        self.log(f"Starting scan on {target} (ports {start_port}-{end_port})")
        self.scan_active = True
        self.scan_btn.config(state="disabled")
        self.progress.start()
        
        # Create queue and threads
        queue = Queue()
        
        # Start scan in thread
        scan_thread = threading.Thread(target=self.perform_scan, 
                                      args=(target, start_port, end_port, queue))
        scan_thread.daemon = True
        scan_thread.start()
        
    def perform_scan(self, target, start_port, end_port, queue):
        """Perform the actual scanning in threads"""
        threads = []
        
        for port in range(start_port, end_port + 1):
            thread = threading.Thread(target=self.scan_port, args=(target, port, queue))
            thread.daemon = True
            thread.start()
            threads.append(thread)
            
            # Limit concurrent threads
            if len(threads) >= 100:
                for t in threads:
                    t.join()
                threads = []
                
        # Wait for remaining threads
        for thread in threads:
            thread.join()
            
        # Update UI when done
        self.master.after(0, self.scan_complete)
        
    def scan_complete(self):
        """Called when scan completes"""
        self.progress.stop()
        self.scan_btn.config(state="normal")
        self.scan_active = False
        self.log(f"Scan complete. Found {len(self.open_ports)} open ports.")

# Main execution
if __name__ == "__main__":
    root = tk.Tk()
    app = CatScanner(root)
    
    # Configure window resizing
    root.columnconfigure(0, weight=1)
    root.rowconfigure(0, weight=1)
    
    root.mainloop()
