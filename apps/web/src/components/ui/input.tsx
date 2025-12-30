import * as React from "react"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "@/lib/utils"

const inputVariants = cva(
  "flex w-full px-4 py-3 text-sm transition-all duration-200 placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50 file:border-0 file:bg-transparent file:text-sm file:font-medium",
  {
    variants: {
      variant: {
        // Glassmorphic input (default)
        default: [
          "rounded-xl",
          "bg-white/5 backdrop-blur-md",
          "border border-white/10",
          "text-foreground",
          "focus:bg-white/8",
          "focus:border-[var(--neon-blue)]",
          "focus:shadow-[0_0_20px_rgba(0,243,255,0.2)]",
          "focus:outline-none"
        ],
        // Neumorphic input
        neuro: [
          "rounded-xl",
          "bg-[rgba(20,20,35,0.4)]",
          "border-none",
          "text-foreground",
          "shadow-[inset_3px_3px_6px_var(--neuro-shadow-dark),inset_-2px_-2px_4px_var(--neuro-shadow-light)]",
          "focus:shadow-[inset_4px_4px_8px_var(--neuro-shadow-dark),inset_-3px_-3px_6px_var(--neuro-shadow-light),0_0_0_2px_var(--neon-blue)]",
          "focus:outline-none"
        ],
        // Solid background
        solid: [
          "rounded-xl",
          "bg-secondary",
          "border border-border",
          "text-foreground",
          "focus:border-primary",
          "focus:ring-2 focus:ring-primary/20",
          "focus:outline-none"
        ]
      },
      inputSize: {
        default: "h-auto py-3",
        sm: "h-auto py-2 text-sm",
        lg: "h-auto py-4 text-base",
      }
    },
    defaultVariants: {
      variant: "default",
      inputSize: "default",
    },
  }
)

export interface InputProps
  extends React.InputHTMLAttributes<HTMLInputElement>,
    VariantProps<typeof inputVariants> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, variant, inputSize, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(inputVariants({ variant, inputSize, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Input.displayName = "Input"

export { Input, inputVariants }
