'use client';

import { useEffect, useRef } from 'react';
import * as THREE from 'three';

export function HeroScene() {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const renderer = new THREE.WebGLRenderer({
      canvas,
      alpha: true,
      antialias: true,
    });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.75));

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(42, 1, 0.1, 100);
    camera.position.set(0, 0.25, 7);

    const group = new THREE.Group();
    scene.add(group);

    const coreMaterial = new THREE.MeshPhysicalMaterial({
      color: '#ffffff',
      roughness: 0.34,
      metalness: 0.04,
      transmission: 0.12,
      thickness: 0.7,
    });
    const accentMaterials = [
      new THREE.MeshStandardMaterial({ color: '#ff69b4', roughness: 0.42 }),
      new THREE.MeshStandardMaterial({ color: '#d4488e', roughness: 0.44 }),
      new THREE.MeshStandardMaterial({ color: '#e8a94b', roughness: 0.48 }),
    ];
    const ringMaterial = new THREE.MeshBasicMaterial({
      color: '#ffffff',
      transparent: true,
      opacity: 0.34,
    });

    const core = new THREE.Mesh(
      new THREE.IcosahedronGeometry(1.08, 4),
      coreMaterial,
    );
    group.add(core);

    const rings: THREE.Mesh[] = [];
    for (let index = 0; index < 3; index++) {
      const ring = new THREE.Mesh(
        new THREE.TorusGeometry(2 + index * 0.42, 0.012, 10, 128),
        ringMaterial,
      );
      ring.rotation.x = Math.PI / 2.8 + index * 0.34;
      ring.rotation.y = index * 0.46;
      group.add(ring);
      rings.push(ring);
    }

    const satellites: THREE.Mesh[] = [];
    for (let index = 0; index < 10; index++) {
      const mesh = new THREE.Mesh(
        new THREE.SphereGeometry(0.1 + (index % 3) * 0.034, 24, 24),
        accentMaterials[index % accentMaterials.length],
      );
      group.add(mesh);
      satellites.push(mesh);
    }

    scene.add(new THREE.AmbientLight('#ffffff', 1.8));
    const key = new THREE.DirectionalLight('#ffffff', 2.3);
    key.position.set(2.4, 3.4, 5);
    scene.add(key);

    const clock = new THREE.Clock();
    let frame = 0;
    let disposed = false;

    const resize = () => {
      const rect = canvas.getBoundingClientRect();
      const width = Math.max(1, rect.width);
      const height = Math.max(1, rect.height);
      renderer.setSize(width, height, false);
      camera.aspect = width / height;
      camera.updateProjectionMatrix();
    };
    const observer = new ResizeObserver(resize);
    observer.observe(canvas);
    resize();

    const animate = () => {
      if (disposed) return;
      const elapsed = clock.getElapsedTime();
      core.rotation.x = elapsed * 0.18;
      core.rotation.y = elapsed * 0.25;
      group.rotation.y = Math.sin(elapsed * 0.16) * 0.16;
      group.position.y = Math.sin(elapsed * 0.82) * 0.08;

      rings.forEach((ring, index) => {
        ring.rotation.z = elapsed * (0.12 + index * 0.04);
      });

      satellites.forEach((satellite, index) => {
        const radius = 2.02 + (index % 3) * 0.42;
        const speed = 0.37 + (index % 4) * 0.08;
        const angle = elapsed * speed + index * 0.78;
        satellite.position.set(
          Math.cos(angle) * radius,
          Math.sin(angle * 0.8 + index) * 0.5,
          Math.sin(angle) * radius * 0.44,
        );
      });

      renderer.render(scene, camera);
      frame = requestAnimationFrame(animate);
    };
    animate();

    return () => {
      disposed = true;
      cancelAnimationFrame(frame);
      observer.disconnect();
      scene.traverse((object) => {
        const mesh = object as THREE.Mesh;
        mesh.geometry?.dispose();
      });
      coreMaterial.dispose();
      ringMaterial.dispose();
      accentMaterials.forEach((material) => material.dispose());
      renderer.dispose();
    };
  }, []);

  return <canvas ref={canvasRef} className="hero-scene" aria-hidden="true" />;
}
