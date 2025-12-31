'use client';

import { useState, useMemo, useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { OrbitControls, Sphere, Line, Html } from '@react-three/drei';
import * as THREE from 'three';
import type { MemoryNode, MemoryRoom } from './page';

function MemorySphere({
  node,
  isHovered,
  onHover,
  onClick
}: {
  node: MemoryNode;
  isHovered: boolean;
  onHover: (id: string | null) => void;
  onClick: () => void;
}) {
  const meshRef = useRef<THREE.Mesh>(null);
  const [hovered, setLocalHovered] = useState(false);

  useFrame(() => {
    if (meshRef.current) {
      meshRef.current.scale.setScalar(hovered || isHovered ? 1.3 : 1);
      meshRef.current.rotation.y += 0.02;
    }
  });

  const finalHovered = hovered || isHovered;

  return (
    <group position={node.position}>
      <Sphere
        ref={meshRef}
        args={[0.4, 32, 32]}
        onClick={(e) => {
          e.stopPropagation();
          onClick();
        }}
        onPointerOver={(e) => {
          e.stopPropagation();
          setLocalHovered(true);
          onHover(node.id);
          document.body.style.cursor = 'pointer';
        }}
        onPointerOut={() => {
          setLocalHovered(false);
          onHover(null);
          document.body.style.cursor = 'default';
        }}
      >
        <meshStandardMaterial
          color={finalHovered ? '#ffffff' : node.color}
          emissive={finalHovered ? node.color : '#000000'}
          emissiveIntensity={finalHovered ? 0.5 : 0.2}
          transparent
          opacity={0.9}
        />
      </Sphere>

      {/* Connection line to center */}
      <Line
        points={[[0, 0, 0], [0, -1, 0]]}
        color={node.color}
        lineWidth={1}
        transparent
        opacity={0.3}
      />

      {/* Label */}
      <Html position={[0, 0.8, 0]} center distanceFactor={15}>
        <div className={`px-2 py-1 rounded text-xs whitespace-nowrap ${
          finalHovered ? 'bg-slate-800 text-white' : 'bg-slate-900/80 text-gray-300'
        }`}>
          {node.topic}
        </div>
      </Html>
    </group>
  );
}

function RoomConnection({
  start,
  end
}: {
  start: [number, number, number];
  end: [number, number, number];
}) {
  return (
    <Line
      points={[start, end]}
      color="#444"
      lineWidth={2}
      transparent
      opacity={0.5}
      dashed
      dashScale={2}
      dashSize={0.5}
    />
  );
}

function MemoryPalaceScene({ rooms, onNodeClick }: {
  rooms: MemoryRoom[];
  onNodeClick: (node: MemoryNode) => void;
}) {
  const [hoveredNode, setHoveredNode] = useState<string | null>(null);

  return (
    <>
      {/* Rooms */}
      {rooms.map((room) => (
        <group key={room.id} position={room.position}>
          {/* Room floor */}
          <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -2, 0]}>
            <circleGeometry args={[4, 32]} />
            <meshStandardMaterial
              color="#1a1a2e"
              transparent
              opacity={0.5}
            />
          </mesh>

          {/* Room label */}
          <Html position={[0, 3, 0]} center>
            <div className="px-3 py-1 bg-neon-blue/20 border border-neon-blue/50 rounded text-white text-sm whitespace-nowrap">
              {room.name}
            </div>
          </Html>

          {/* Memory nodes */}
          {room.nodes.map((node) => (
            <MemorySphere
              key={node.id}
              node={node}
              isHovered={hoveredNode === node.id}
              onHover={setHoveredNode}
              onClick={() => onNodeClick(node)}
            />
          ))}
        </group>
      ))}

      {/* Connections between rooms */}
      {rooms.slice(0, -1).map((room, index) => (
        <RoomConnection
          key={`conn-${room.id}`}
          start={[room.position[0] + 3, 0, 0]}
          end={[rooms[index + 1].position[0] - 3, 0, 0]}
        />
      ))}

      {/* Camera controls */}
      <OrbitControls
        enablePan={true}
        enableZoom={true}
        enableRotate={true}
        maxPolarAngle={Math.PI / 1.5}
        minPolarAngle={Math.PI / 4}
        autoRotate={!hoveredNode}
        autoRotateSpeed={0.5}
      />

      {/* Lighting */}
      <ambientLight intensity={0.4} />
      <pointLight position={[10, 10, 10]} intensity={1} />
      <pointLight position={[-10, 10, -10]} intensity={0.5} color="#00f3ff" />
    </>
  );
}

function FloatingParticles() {
  const particles = useMemo(() => {
    const positions = [];
    for (let i = 0; i < 100; i++) {
      const x = (Math.random() - 0.5) * 50;
      const y = (Math.random() - 0.5) * 20;
      const z = (Math.random() - 0.5) * 50;
      positions.push(x, y, z);
    }
    return new Float32Array(positions);
  }, []);

  return (
    <points>
      <bufferGeometry>
        <bufferAttribute
          attach="attributes-position"
          args={[particles, 3]}
        />
      </bufferGeometry>
      <pointsMaterial size={0.05} color="#ffffff" transparent opacity={0.6} />
    </points>
  );
}

export default function MemoryPalace3D({ rooms, onNodeClick }: {
  rooms: MemoryRoom[];
  onNodeClick: (node: MemoryNode) => void;
}) {
  return (
    <div className="w-full h-screen bg-gradient-to-b from-slate-900 to-purple-950">
      <Canvas camera={{ position: [0, 5, 20], fov: 60 }}>
        <color attach="background" args={['#0a0a1a']} />
        <MemoryPalaceScene rooms={rooms} onNodeClick={onNodeClick} />
        <FloatingParticles />
      </Canvas>
    </div>
  );
}
